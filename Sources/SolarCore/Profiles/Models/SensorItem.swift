// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - SensorItem

/// Sensor item definition from upstream ha-solarman format.
///
/// Represents a single sensor/entity in the inverter profile.
/// All optional YAML fields have sensible defaults for ergonomic API usage.
///
/// ## Example YAML
///
/// ```yaml
/// - name: "Battery SOC"
///   class: "battery"
///   state_class: "measurement"
///   uom: "%"
///   rule: 1
///   registers: [0x00B8]
///   icon: "mdi:battery"
/// ```
///
/// ## Usage
///
/// ```swift
/// let item = try decoder.decode(SensorItem.self, from: yaml)
/// print(item.name)           // "Battery SOC"
/// print(item.registers)      // [184] as [UInt16]
/// print(item.scale)          // 1.0 (default)
/// print(item.isReadOnly)     // true
/// ```
public struct SensorItem: Sendable, Equatable {
    // MARK: Lifecycle

    // MARK: - Initializer

    public init(
        name: String,
        registers: [UInt16],
        rule: ParsingRule,
        platform: Platform = .sensor,
        deviceClass: DeviceClass? = nil,
        stateClass: StateClass? = nil,
        uom: String = "",
        icon: String? = nil,
        scale: Double = 1.0,
        offset: Double = 0.0,
        signed: Bool = false,
        inverse: Bool = false,
        magnitude: Bool = false,
        mask: UInt32? = nil,
        divide: UInt32? = nil,
        bit: UInt8? = nil,
        rangeMin: Double? = nil,
        rangeMax: Double? = nil,
        rangeDefault: Double? = nil,
        validationMin: Double? = nil,
        validationMax: Double? = nil,
        lookup: [LookupEntry] = [],
        options: [String] = [],
        subSensors: [SubSensor] = [],
        attributeNames: [String] = [],
        isAttribute: Bool = false,
        description: String? = nil,
        updateInterval: Int? = nil,
        versionDelimiter: VersionDelimiter = .default,
        hex: Bool = false,
    ) {
        self.name = name
        self.registers = registers
        self.rule = rule
        self.platform = platform
        self.deviceClass = deviceClass
        self.stateClass = stateClass
        self.uom = uom
        self.icon = icon
        self.scale = scale
        self.offset = offset
        self.signed = signed
        self.inverse = inverse
        self.magnitude = magnitude
        self.mask = mask
        self.divide = divide
        self.bit = bit
        self.rangeMin = rangeMin
        self.rangeMax = rangeMax
        self.rangeDefault = rangeDefault
        self.validationMin = validationMin
        self.validationMax = validationMax
        self.lookup = lookup
        self.options = options
        self.subSensors = subSensors
        self.attributeNames = attributeNames
        self.isAttribute = isAttribute
        self.description = description
        self.updateInterval = updateInterval
        self.versionDelimiter = versionDelimiter
        self.hex = hex
    }

    // MARK: Public

    // MARK: - Core Fields (Required)

    /// Display name.
    public let name: String

    /// Modbus register addresses.
    public let registers: [UInt16]

    /// Parsing rule for value interpretation.
    public let rule: ParsingRule

    // MARK: - Platform & Classification (with defaults)

    /// Entity platform type.
    public let platform: Platform

    /// Device class for UI presentation.
    public let deviceClass: DeviceClass?

    /// State class for value accumulation.
    public let stateClass: StateClass?

    /// Unit of measurement.
    public let uom: String

    /// MDI icon name.
    public let icon: String?

    // MARK: - Value Transformation (with defaults)

    /// Scale factor (multiplier). Default: 1.0
    public let scale: Double

    /// Offset subtracted before scaling (ha-solarman convention). Default: 0.0
    ///
    /// Used by temperature sensors where raw value includes a bias:
    /// - Temperature: `offset: 1000` → `(raw - 1000) * scale`
    ///
    /// Formula: `value = (raw - offset) * scale`
    public let offset: Double

    /// Force signed interpretation.
    public let signed: Bool

    /// Invert sign of value.
    public let inverse: Bool

    /// Use sign-magnitude encoding instead of two's complement.
    /// In sign-magnitude: MSB is sign bit, remaining bits are absolute value.
    /// Example 16-bit: 0x8001 = -1 (vs -32767 in two's complement)
    public let magnitude: Bool

    // MARK: - Bit Manipulation

    /// Bitmask applied to raw value before transformation.
    /// Formula: `value = rawValue & mask`
    public let mask: UInt32?

    /// Integer divisor applied after transformation.
    /// Formula: `value = transformedValue / divide` (integer division)
    public let divide: UInt32?

    /// Bit position to extract (0-31).
    /// Formula: `value = (rawValue >> bit) & 1`
    /// Applied after mask, before transformation.
    public let bit: UInt8?

    // MARK: - Range (raw value filtering)

    /// Minimum raw value before transformation.
    /// Values below this return `rangeDefault` or are skipped.
    public let rangeMin: Double?

    /// Maximum raw value before transformation.
    /// Values above this return `rangeDefault` or are skipped.
    public let rangeMax: Double?

    /// Default value to return if raw value is outside range.
    /// If nil and value is out of range, sensor is skipped.
    public let rangeDefault: Double?

    // MARK: - Validation (post-transformation)

    /// Minimum valid value after transformation.
    public let validationMin: Double?

    /// Maximum valid value after transformation.
    public let validationMax: Double?

    // MARK: - Enum/Lookup

    /// Lookup table for enum values.
    public let lookup: [LookupEntry]

    /// Options for computed enum (rule 0).
    public let options: [String]

    // MARK: - Composite Sensors

    /// Sub-sensors for aggregation.
    public let subSensors: [SubSensor]

    /// Related attribute sensor names.
    public let attributeNames: [String]

    // MARK: - Metadata

    /// Mark as attribute (not standalone sensor).
    public let isAttribute: Bool

    /// Sensor description.
    public let description: String?

    /// Custom update interval (overrides group default).
    public let updateInterval: Int?

    // MARK: - Version Parsing (rule 7)

    /// Delimiter configuration for version parsing.
    ///
    /// For version rule (rule 7), controls how nibbles and registers are joined:
    /// - `digitDelimiter`: Separator between nibbles within a register (default: ".")
    /// - `registerDelimiter`: Separator between registers (default: "-")
    ///
    /// ## YAML Examples
    ///
    /// ```yaml
    /// # Default behavior: "1.2.3.4-5.6.7.8"
    /// delimiter: "."
    ///
    /// # No separators: "12345678"
    /// delimiter: ""
    ///
    /// # Custom separators
    /// delimiter:
    ///   digit: "."
    ///   register: "-"
    /// ```
    public let versionDelimiter: VersionDelimiter

    /// Output hex digits instead of decimal (for version rule).
    public let hex: Bool
}

// MARK: - VersionDelimiter

/// Delimiter configuration for version string parsing (rule 7).
///
/// Controls how nibbles and registers are joined in version strings.
/// Matches ha-solarman behavior.
public struct VersionDelimiter: Sendable, Equatable {
    // MARK: Lifecycle

    public init(digit: String, register: String) {
        self.digit = digit
        self.register = register
    }

    /// Create from a simple string delimiter.
    /// When delimiter is a string, it's used for digits and "-" for registers.
    public init(delimiter: String) {
        digit = delimiter
        register = "-"
    }

    // MARK: Public

    /// Default delimiter: "." between nibbles, "-" between registers.
    public static let `default` = VersionDelimiter(digit: ".", register: "-")

    /// No delimiters: concatenate all nibbles.
    public static let none = VersionDelimiter(digit: "", register: "")

    /// Separator between nibbles within a register.
    /// Default: "." → "1.2.3.4"
    public let digit: String

    /// Separator between registers.
    /// Default: "-" → "1.2.3.4-5.6.7.8"
    public let register: String
}

// MARK: - SensorItem.SubSensor

extension SensorItem {
    /// Sub-sensor for composite aggregation.
    public struct SubSensor: Sendable, Codable, Equatable {
        // MARK: Lifecycle

        public init(
            registers: [UInt16],
            scale: Double = 1.0,
            offset: Double = 0.0,
            signed: Bool = false,
            operator: Operator = .add,
        ) {
            self.registers = registers
            self.scale = scale
            self.offset = offset
            self.signed = signed
            self.operator = `operator`
        }

        // MARK: Public

        public enum Operator: String, Sendable, Codable, Equatable {
            case add
            case subtract
            case multiply
            case divide
        }

        public let registers: [UInt16]
        public let scale: Double
        public let offset: Double
        public let signed: Bool
        public let `operator`: Operator
    }
}

// MARK: - Convenience Properties

extension SensorItem {
    /// Whether this is a read-only sensor.
    public var isReadOnly: Bool {
        platform.isReadOnly
    }

    /// Whether this is a computed sensor (no registers).
    public var isComputed: Bool {
        rule == .computed || registers.isEmpty
    }

    /// Whether this sensor has lookup values.
    public var hasLookup: Bool {
        !lookup.isEmpty
    }

    /// Whether this is a composite sensor with sub-sensors.
    public var isComposite: Bool {
        !subSensors.isEmpty
    }

    /// Starting register address.
    public var startAddress: UInt16? {
        registers.min()
    }

    /// Ending register address.
    public var endAddress: UInt16? {
        registers.max()
    }

    /// Number of registers.
    public var registerCount: Int {
        registers.count
    }

    /// Normalized sensor ID for internal matching.
    ///
    /// Converts human-readable name to snake_case ID:
    /// - "Battery SOC" → "battery_soc"
    /// - "Grid L1 Voltage" → "grid_l1_voltage"
    /// - "PV1 Power" → "pv1_power"
    public var normalizedId: String {
        name
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
    }

    /// Check if raw value is within range (ha-solarman `range` filtering).
    ///
    /// - Parameter rawValue: The raw register value before transformation.
    /// - Returns: `true` if within range or no range defined, `false` if out of range.
    public func isInRange(_ rawValue: Double) -> Bool {
        if let min = rangeMin, rawValue < min {
            return false
        }
        if let max = rangeMax, rawValue > max {
            return false
        }
        return true
    }

    /// Apply transformation to raw value.
    ///
    /// Formula follows ha-solarman convention:
    /// `value = (rawValue - offset) * scale`
    ///
    /// - Note: Offset is subtracted before scaling (e.g., temperature sensors
    ///   use offset=1000 to convert from raw register to Celsius).
    public func transform(_ rawValue: Double) -> Double {
        var value = (rawValue - offset) * scale
        if inverse {
            value = -value
        }
        return value
    }

    /// Validate a value against post-transformation constraints.
    public func isValid(_ value: Double) -> Bool {
        if let min = validationMin, value < min {
            return false
        }
        if let max = validationMax, value > max {
            return false
        }
        return true
    }

    /// Look up enum value.
    public func lookupValue(for registerValue: Int) -> String? {
        lookup.value(for: registerValue)
    }
}
