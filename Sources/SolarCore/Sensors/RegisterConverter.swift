// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

import SolarmanV5

// FoundationEssentials: basic types
// FoundationInternationalization: IntegerFormatStyle for zero-padded formatting
#if canImport(FoundationEssentials)
    import FoundationEssentials
    import FoundationInternationalization
#else
    import Foundation
#endif

// MARK: - RegisterConverter

/// Converts raw Modbus register values using upstream ha-solarman parsing rules.
///
/// Reuses ModbusCore's `decodeUInt32`/`decodeInt32` for 32-bit values.
///
/// ## Parsing Rules
///
/// | Rule | Type | Description |
/// |------|------|-------------|
/// | 1 | U16 | Unsigned 16-bit |
/// | 2 | S16 | Signed 16-bit |
/// | 3 | U32 | Unsigned 32-bit (high word first) |
/// | 4 | S32 | Signed 32-bit (high word first) |
/// | 5 | String | UTF-8 string (2 bytes per register) |
/// | 7 | Version | Nibble-delimited string |
/// | 9 | Time | Time value (HHMM) |
///
/// ## Example
///
/// ```swift
/// let converter = RegisterConverter()
/// let value = try converter.convert(registers: [512], item: batterySOC)
/// ```
public struct RegisterConverter: Sendable {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    /// Convert raw registers to Double using sensor item definition.
    ///
    /// Processing order:
    /// 1. Parse raw value from registers using rule
    /// 2. Check range (raw value filtering) - return default or throw if out of range
    /// 3. Apply mask: `value &= mask`
    /// 4. Apply bit extraction: `value = (value >> bit) & 1`
    /// 5. Apply transformation: `(raw - offset) * scale`
    /// 6. Apply divide (integer division): `value /= divide`
    /// 7. Validate transformed value - throw if out of range
    ///
    /// - Parameters:
    ///   - registers: Raw register values.
    ///   - item: Sensor item with rule, scale, and validation.
    /// - Returns: Converted and scaled value.
    /// - Throws: `SensorError` if conversion fails or value is invalid.
    public func convert(
        registers: [UInt16],
        item: SensorItem,
    ) throws(SensorError) -> Double {
        var rawValue = try convertRaw(
            registers: registers,
            rule: item.rule,
            signed: item.signed,
            magnitude: item.magnitude,
        )

        // Step 2: Range check (raw value filtering)
        if !item.isInRange(rawValue) {
            if let defaultValue = item.rangeDefault {
                return item.transform(defaultValue)
            }
            throw .rawValueOutOfRange(
                value: rawValue,
                min: item.rangeMin,
                max: item.rangeMax,
            )
        }

        // Step 3: Apply mask (before transformation)
        if let mask = item.mask {
            rawValue = Double(UInt32(rawValue) & mask)
        }

        // Step 3.5: Apply bit extraction (after mask, before transformation)
        // Extracts single bit at specified position: (value >> bit) & 1
        if let bit = item.bit {
            rawValue = Double((UInt32(rawValue) >> bit) & 1)
        }

        // Step 4: Apply transformation (offset, scale, inverse)
        var scaledValue = item.transform(rawValue)

        // Step 5: Apply divide (after transformation, integer division)
        if let divide = item.divide, divide > 0 {
            scaledValue = Double(Int(scaledValue) / Int(divide))
        }

        // Step 6: Validate transformed value
        if !item.isValid(scaledValue) {
            throw .valueOutOfRange(
                value: scaledValue,
                min: item.validationMin,
                max: item.validationMax,
            )
        }

        return scaledValue
    }

    /// Convert raw registers to Double without scaling.
    ///
    /// - Parameters:
    ///   - registers: Raw register values.
    ///   - rule: Parsing rule.
    ///   - signed: Force signed interpretation.
    ///   - magnitude: Use sign-magnitude encoding instead of two's complement.
    /// - Returns: Raw numeric value.
    public func convertRaw(
        registers: [UInt16],
        rule: ParsingRule,
        signed: Bool = false,
        magnitude: Bool = false,
    ) throws(SensorError) -> Double {
        switch rule {
        case .computed:
            throw .unsupportedRule(rule)

        case .uint16:
            guard let value = registers.first else {
                throw .insufficientRegisters(expected: 1, got: 0)
            }
            if signed {
                return magnitude
                    ? signMagnitude16(value)
                    : Double(Int16(bitPattern: value))
            }
            return Double(value)

        case .int16:
            guard let value = registers.first else {
                throw .insufficientRegisters(expected: 1, got: 0)
            }
            return magnitude
                ? signMagnitude16(value)
                : Double(Int16(bitPattern: value))

        case .uint32:
            guard registers.count >= 2 else {
                throw .insufficientRegisters(expected: 2, got: registers.count)
            }
            if signed {
                let raw = decodeUInt32((registers[0], registers[1]), order: .cdab)
                return magnitude
                    ? signMagnitude32(raw)
                    : Double(Int32(bitPattern: raw))
            }
            return Double(decodeUInt32((registers[0], registers[1]), order: .cdab))

        case .int32:
            guard registers.count >= 2 else {
                throw .insufficientRegisters(expected: 2, got: registers.count)
            }
            let raw = decodeUInt32((registers[0], registers[1]), order: .cdab)
            return magnitude
                ? signMagnitude32(raw)
                : Double(Int32(bitPattern: raw))

        case .time:
            guard let value = registers.first else {
                throw .insufficientRegisters(expected: 1, got: 0)
            }
            let hours = value / 100
            let minutes = value % 100
            return Double(hours * 60 + minutes)

        case .ascii,
             .bits,
             .version,
             .datetime,
             .raw:
            throw .unsupportedRule(rule)
        }
    }

    /// Convert registers to UTF-8 string (rule 5).
    ///
    /// Each register contains 2 bytes (high byte first).
    /// Stops at null terminator.
    ///
    /// - Parameter registers: Raw register values.
    /// - Returns: Decoded UTF-8 string.
    /// - Throws: `SensorError` if validation fails.
    public func convertString(registers: [UInt16]) throws(SensorError) -> String {
        var bytes: [UInt8] = []
        bytes.reserveCapacity(registers.count * 2)

        for register in registers {
            let highByte = UInt8((register >> 8) & 0xFF)
            let lowByte = UInt8(register & 0xFF)

            if highByte == 0 {
                break
            }
            bytes.append(highByte)

            if lowByte == 0 {
                break
            }
            bytes.append(lowByte)
        }

        guard let result = String(validating: bytes, as: UTF8.self) else {
            throw .invalidUTF8
        }

        // Security: reject control characters
        for scalar in result.unicodeScalars {
            let value = scalar.value
            if value < 0x20 || value == 0x7F || (value >= 0x80 && value <= 0x9F) {
                throw .controlCharacter(value)
            }
        }

        return result
    }

    /// Convert registers to version string (rule 7).
    ///
    /// Breaks each register into 4-bit nibbles joined with configurable delimiters.
    /// Matches ha-solarman behavior.
    ///
    /// - Parameters:
    ///   - registers: Raw register values.
    ///   - delimiter: Delimiter configuration (default: "." between digits, "-" between registers).
    ///   - hex: Output as hex digits if true (default: true for consistency with ha-solarman).
    /// - Returns: Version string (e.g., "2.0.0.6-1.1.5.1-1.8.0.7" with defaults).
    public func convertVersion(
        registers: [UInt16],
        delimiter: VersionDelimiter = .default,
        hex: Bool = true,
    ) -> String {
        var registerStrings: [String] = []

        for register in registers {
            let nibbles = [
                (register >> 12) & 0xF,
                (register >> 8) & 0xF,
                (register >> 4) & 0xF,
                register & 0xF,
            ]

            let nibbleStrings: [String] =
                if hex {
                    nibbles.map { String($0, radix: 16).uppercased() }
                } else {
                    nibbles.map { String($0) }
                }

            registerStrings.append(nibbleStrings.joined(separator: delimiter.digit))
        }

        var result = registerStrings.joined(separator: delimiter.register)

        // Remove trailing register delimiter if present
        if !delimiter.register.isEmpty, result.hasSuffix(delimiter.register) {
            result = String(result.dropLast(delimiter.register.count))
        }

        // Strip leading zeros for cleaner output (only if using digit delimiter)
        if !delimiter.digit.isEmpty, let firstChar = delimiter.digit.first {
            let parts = result.split(separator: firstChar, omittingEmptySubsequences: false)
            var trimmed = false
            var finalParts: [String] = []
            for part in parts {
                if !trimmed, part == "0" {
                    continue
                }
                trimmed = true
                finalParts.append(String(part))
            }
            if !finalParts.isEmpty {
                result = finalParts.joined(separator: delimiter.digit)
            }
        }

        return result
    }

    /// Convert registers to time string (rule 9).
    ///
    /// - Parameter registers: Raw register value in HHMM format.
    /// - Returns: Time string "HH:MM".
    public func convertTime(registers: [UInt16]) -> String? {
        guard let value = registers.first else {
            return nil
        }
        let hours = value / 100
        let minutes = value % 100
        return "\(hours.formatted(Self.twoDigit)):\(minutes.formatted(Self.twoDigit))"
    }

    /// Convert registers to datetime string (rule 8).
    ///
    /// Supports two formats:
    /// - **3-register (Deye)**: Each register contains two components
    ///   - Register 0: high byte = year, low byte = month
    ///   - Register 1: high byte = day, low byte = hour
    ///   - Register 2: high byte = minute, low byte = second
    /// - **6-register (Solis)**: Each register is a single component (Y, M, D, H, M, S)
    ///
    /// - Parameter registers: Raw register values (3 or 6).
    /// - Returns: Datetime string in `YY/MM/DD HH:MM:SS` format, or nil.
    public func convertDateTime(registers: [UInt16]) -> String? {
        let year: UInt16
        let month: UInt16
        let day: UInt16
        let hour: UInt16
        let minute: UInt16
        let second: UInt16

        switch registers.count {
        case 3:
            // 3-register format: each register has two components (high/low byte)
            year = registers[0] >> 8
            month = registers[0] & 0xFF
            day = registers[1] >> 8
            hour = registers[1] & 0xFF
            minute = registers[2] >> 8
            second = registers[2] & 0xFF

        case 6:
            // 6-register format: each register is a single component
            year = registers[0]
            month = registers[1]
            day = registers[2]
            hour = registers[3]
            minute = registers[4]
            second = registers[5]

        default:
            return nil
        }

        return "\(year.formatted(Self.twoDigit))/\(month.formatted(Self.twoDigit))/\(day.formatted(Self.twoDigit)) \(hour.formatted(Self.twoDigit)):\(minute.formatted(Self.twoDigit)):\(second.formatted(Self.twoDigit))"
    }

    /// Lookup enum value from register.
    ///
    /// - Parameters:
    ///   - registers: Raw register values.
    ///   - lookup: Lookup table.
    /// - Returns: Matched string value or nil.
    public func lookupValue(
        registers: [UInt16],
        lookup: [LookupEntry],
    ) -> String? {
        guard let value = registers.first else {
            return nil
        }
        return lookup.value(for: Int(value))
    }

    // MARK: Private

    /// Two-digit zero-padded integer format style.
    ///
    /// Replacement for `String(format: "%02d", value)` using modern FormatStyle API.
    private static let twoDigit = IntegerFormatStyle<UInt16>().precision(.integerLength(2))

    /// Convert 16-bit sign-magnitude to signed value.
    /// MSB (bit 15) is sign, bits 0-14 are magnitude.
    private func signMagnitude16(_ value: UInt16) -> Double {
        let signBit = value & 0x8000
        let magnitude = value & 0x7FFF
        return signBit != 0 ? -Double(magnitude) : Double(magnitude)
    }

    /// Convert 32-bit sign-magnitude to signed value.
    /// MSB (bit 31) is sign, bits 0-30 are magnitude.
    private func signMagnitude32(_ value: UInt32) -> Double {
        let signBit = value & 0x8000_0000
        let magnitude = value & 0x7FFF_FFFF
        return signBit != 0 ? -Double(magnitude) : Double(magnitude)
    }
}
