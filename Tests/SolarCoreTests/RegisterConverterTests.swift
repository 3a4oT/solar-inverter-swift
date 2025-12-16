// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

@testable import SolarCore
import Testing

/// Tests for RegisterConverter using upstream ha-solarman parsing rules.
///
/// Test vectors derived from:
/// - ha-solarman deye_sg04lp3.yaml
/// - Real inverter data captures
@Suite("RegisterConverter")
struct RegisterConverterTests {
    // MARK: - UInt16 Tests (Rule 1)

    @Suite("UInt16 (Rule 1)")
    struct UInt16Tests {
        let converter = RegisterConverter()

        @Test("Battery SOC - rule 1, scale 1")
        func batterySOC() throws {
            let registers: [UInt16] = [85]
            let result = try converter.convertRaw(
                registers: registers,
                rule: .uint16,
            )
            #expect(result == 85.0)
        }

        @Test("PV1 Power - rule 1, scale 1")
        func pv1Power() throws {
            let registers: [UInt16] = [3250]
            let result = try converter.convertRaw(
                registers: registers,
                rule: .uint16,
            )
            #expect(result == 3250.0)
        }

        @Test("With scale 0.1 via SensorItem")
        func withScale() throws {
            let item = SensorItem(
                name: "PV1 Voltage",
                registers: [109],
                rule: .uint16,
                scale: 0.1,
            )
            let result = try converter.convert(
                registers: [3856],
                item: item,
            )
            #expect(result == 385.6)
        }

        @Test("Empty registers throws error")
        func emptyRegisters() throws {
            #expect(throws: SensorError.insufficientRegisters(expected: 1, got: 0)) {
                try converter.convertRaw(registers: [], rule: .uint16)
            }
        }

        @Test("Signed flag interprets as Int16")
        func signedFlag() throws {
            let registers: [UInt16] = [UInt16(bitPattern: -1500)]
            let result = try converter.convertRaw(
                registers: registers,
                rule: .uint16,
                signed: true,
            )
            #expect(result == -1500.0)
        }
    }

    // MARK: - Int16 Tests (Rule 2)

    @Suite("Int16 (Rule 2)")
    struct Int16Tests {
        let converter = RegisterConverter()

        @Test("Positive value")
        func positiveValue() throws {
            let registers: [UInt16] = [1500]
            let result = try converter.convertRaw(
                registers: registers,
                rule: .int16,
            )
            #expect(result == 1500.0)
        }

        @Test("Negative value - two's complement")
        func negativeValue() throws {
            let registers: [UInt16] = [UInt16(bitPattern: -2000)]
            let result = try converter.convertRaw(
                registers: registers,
                rule: .int16,
            )
            #expect(result == -2000.0)
        }

        @Test("Battery power charging (negative)")
        func batteryCharging() throws {
            let item = SensorItem(
                name: "Battery Power",
                registers: [190],
                rule: .int16,
            )
            let result = try converter.convert(
                registers: [UInt16(bitPattern: -3000)],
                item: item,
            )
            #expect(result == -3000.0)
        }

        @Test("Battery power discharging (positive)")
        func batteryDischarging() throws {
            let item = SensorItem(
                name: "Battery Power",
                registers: [190],
                rule: .int16,
            )
            let result = try converter.convert(
                registers: [2500],
                item: item,
            )
            #expect(result == 2500.0)
        }
    }

    // MARK: - UInt32 Tests (Rule 3)

    @Suite("UInt32 (Rule 3)")
    struct UInt32Tests {
        let converter = RegisterConverter()

        @Test("Total production - low word first")
        func totalProduction() throws {
            // 123456 = 0x0001E240 → [0xE240, 0x0001]
            let registers: [UInt16] = [0xE240, 0x0001]
            let result = try converter.convertRaw(
                registers: registers,
                rule: .uint32,
            )
            #expect(result == 123_456.0)
        }

        @Test("Large energy value")
        func largeValue() throws {
            // 1,000,000,000 = 0x3B9ACA00 → [0xCA00, 0x3B9A]
            let registers: [UInt16] = [0xCA00, 0x3B9A]
            let result = try converter.convertRaw(
                registers: registers,
                rule: .uint32,
            )
            #expect(result == 1_000_000_000.0)
        }

        @Test("Insufficient registers throws error")
        func insufficientRegisters() throws {
            #expect(throws: SensorError.insufficientRegisters(expected: 2, got: 1)) {
                try converter.convertRaw(registers: [0x1234], rule: .uint32)
            }
        }

        @Test("With signed flag")
        func signedFlag() throws {
            // 0xFFFFFFFF = -1
            let registers: [UInt16] = [0xFFFF, 0xFFFF]
            let result = try converter.convertRaw(
                registers: registers,
                rule: .uint32,
                signed: true,
            )
            #expect(result == -1.0)
        }
    }

    // MARK: - Int32 Tests (Rule 4)

    @Suite("Int32 (Rule 4)")
    struct Int32Tests {
        let converter = RegisterConverter()

        @Test("Positive value - low word first")
        func positiveValue() throws {
            // 123456 = 0x0001E240 → [0xE240, 0x0001]
            let registers: [UInt16] = [0xE240, 0x0001]
            let result = try converter.convertRaw(
                registers: registers,
                rule: .int32,
            )
            #expect(result == 123_456.0)
        }

        @Test("Negative value - two's complement")
        func negativeValue() throws {
            // -50000 = 0xFFFF3CB0 → [0x3CB0, 0xFFFF]
            let registers: [UInt16] = [0x3CB0, 0xFFFF]
            let result = try converter.convertRaw(
                registers: registers,
                rule: .int32,
            )
            #expect(result == -50000.0)
        }
    }

    // MARK: - Time Tests (Rule 9)

    @Suite("Time (Rule 9)")
    struct TimeTests {
        let converter = RegisterConverter()

        @Test("Morning time 07:30")
        func morningTime() throws {
            // HHMM format: 0730
            let result = try converter.convertRaw(
                registers: [730],
                rule: .time,
            )
            #expect(result == 450.0) // 7*60 + 30 = 450 minutes
        }

        @Test("Afternoon time 14:45")
        func afternoonTime() throws {
            let result = try converter.convertRaw(
                registers: [1445],
                rule: .time,
            )
            #expect(result == 885.0) // 14*60 + 45 = 885 minutes
        }

        @Test("Midnight 00:00")
        func midnight() throws {
            let result = try converter.convertRaw(
                registers: [0],
                rule: .time,
            )
            #expect(result == 0.0)
        }

        @Test("Convert to string")
        func convertToString() {
            let result = converter.convertTime(registers: [1430])
            #expect(result == "14:30")
        }
    }

    // MARK: - String Tests (Rule 5)

    @Suite("String (Rule 5)")
    struct StringTests {
        let converter = RegisterConverter()

        @Test("Serial number - ASCII bytes")
        func serialNumber() throws {
            // "AB12" = 0x4142 0x3132
            let registers: [UInt16] = [0x4142, 0x3132]
            let result = try converter.convertString(registers: registers)
            #expect(result == "AB12")
        }

        @Test("Stops at null terminator")
        func nullTerminator() throws {
            // "AB" followed by null
            let registers: [UInt16] = [0x4142, 0x0000]
            let result = try converter.convertString(registers: registers)
            #expect(result == "AB")
        }

        @Test("Empty string")
        func emptyString() throws {
            let registers: [UInt16] = [0x0000]
            let result = try converter.convertString(registers: registers)
            #expect(result == "")
        }

        @Test("Rejects control characters")
        func controlCharacters() throws {
            // Contains control character 0x01
            let registers: [UInt16] = [0x0141]
            #expect(throws: SensorError.self) {
                try converter.convertString(registers: registers)
            }
        }
    }

    // MARK: - Version Tests (Rule 7)

    @Suite("Version (Rule 7)")
    struct VersionTests {
        let converter = RegisterConverter()

        @Test("Firmware version with default delimiter")
        func firmwareVersionDefault() throws {
            // 0x1234 = nibbles 1,2,3,4 with default "." between nibbles, "-" between registers
            let result = converter.convertVersion(registers: [0x1234])
            #expect(result == "1.2.3.4")
        }

        @Test("Version with leading zeros trimmed")
        func leadingZerosTrimmed() throws {
            // 0x0012 = nibbles 0,0,1,2 -> "1.2"
            let result = converter.convertVersion(registers: [0x0012])
            #expect(result == "1.2")
        }

        @Test("Multi-register version with default delimiter")
        func multiRegisterDefault() throws {
            // Default: "." between nibbles, "-" between registers
            let result = converter.convertVersion(registers: [0x0102, 0x0304])
            #expect(result == "1.0.2-0.3.0.4")
        }

        @Test("Version with no delimiters at all")
        func noDelimiterAtAll() throws {
            // VersionDelimiter.none means both digit and register are empty
            // All nibbles concatenated without any separators
            let result = converter.convertVersion(
                registers: [0x2006, 0x1151, 0x1807],
                delimiter: .none,
            )
            #expect(result == "200611511807")
        }

        @Test("Version with custom digit delimiter")
        func customDigitDelimiter() throws {
            // Custom delimiter: "." for nibbles only
            let result = converter.convertVersion(
                registers: [0x1234, 0x5678],
                delimiter: VersionDelimiter(delimiter: "."),
            )
            #expect(result == "1.2.3.4-5.6.7.8")
        }

        @Test("Version with custom digit and register delimiters")
        func customBothDelimiters() throws {
            // Custom: "." for nibbles, "." for registers (all dots)
            let result = converter.convertVersion(
                registers: [0x1234, 0x5678],
                delimiter: VersionDelimiter(digit: ".", register: "."),
            )
            #expect(result == "1.2.3.4.5.6.7.8")
        }

        @Test("Real Deye firmware version format")
        func realDeyeFirmwareVersion() throws {
            // Real data from Deye inverter with delimiter: ""
            // ha-solarman: delimiter="" means digit delimiter is "", register delimiter is "-"
            // 3 registers produce 4 nibbles each, joined with "-" between registers
            let result = converter.convertVersion(
                registers: [0x0206, 0x0115, 0x0108],
                delimiter: VersionDelimiter(delimiter: ""),
            )
            // Each register's nibbles concatenated, "-" between registers
            #expect(result == "0206-0115-0108")
        }

        @Test("Hex output vs decimal output")
        func hexVsDecimal() throws {
            // 0xABCD = nibbles A(10), B(11), C(12), D(13)
            // Hex output: "A.B.C.D"
            let hexResult = converter.convertVersion(
                registers: [0xABCD],
                hex: true,
            )
            #expect(hexResult == "A.B.C.D")

            // Decimal output would show values but hex is default
            let decimalResult = converter.convertVersion(
                registers: [0xABCD],
                hex: false,
            )
            #expect(decimalResult == "10.11.12.13")
        }
    }

    // MARK: - Lookup Tests

    @Suite("Lookup")
    struct LookupTests {
        let converter = RegisterConverter()

        @Test("Lookup value found")
        func lookupFound() {
            let lookup: [LookupEntry] = [
                LookupEntry(key: 0, value: "Standby"),
                LookupEntry(key: 1, value: "Running"),
                LookupEntry(key: 2, value: "Fault"),
            ]
            let result = converter.lookupValue(registers: [1], lookup: lookup)
            #expect(result == "Running")
        }

        @Test("Lookup value not found")
        func lookupNotFound() {
            let lookup: [LookupEntry] = [
                LookupEntry(key: 0, value: "Standby"),
            ]
            let result = converter.lookupValue(registers: [99], lookup: lookup)
            #expect(result == nil)
        }
    }

    // MARK: - Transformation Tests

    @Suite("Value Transformation")
    struct TransformationTests {
        let converter = RegisterConverter()

        @Test("Scale applied")
        func scaleApplied() throws {
            let item = SensorItem(
                name: "Voltage",
                registers: [100],
                rule: .uint16,
                scale: 0.1,
            )
            let result = try converter.convert(registers: [2300], item: item)
            #expect(result == 230.0)
        }

        @Test("Offset applied - ha-solarman formula (raw - offset) * scale")
        func offsetApplied() throws {
            // DC Temperature in ha-solarman: offset=1000, scale=0.1
            // Formula: (raw - 1000) * 0.1
            // raw=1259 → (1259 - 1000) * 0.1 = 25.9°C
            let item = SensorItem(
                name: "DC Temperature",
                registers: [0x005A],
                rule: .uint16,
                scale: 0.1,
                offset: 1000.0,
            )
            let result = try converter.convert(registers: [1259], item: item)
            // Use rounded comparison to avoid floating point precision issues
            #expect((result * 10).rounded() == 259)
        }

        @Test("Scale and offset combined - ha-solarman formula")
        func scaleAndOffset() throws {
            // Real deye_p3 temperature sensor:
            // offset: 1000, scale: 0.1
            // Formula: (raw - offset) * scale = (raw - 1000) * 0.1
            let item = SensorItem(
                name: "Temperature",
                registers: [100],
                rule: .uint16,
                scale: 0.1,
                offset: 1000.0,
            )
            // raw=1250 → (1250 - 1000) * 0.1 = 25.0°C
            let result = try converter.convert(registers: [1250], item: item)
            #expect(result == 25.0)
        }

        @Test("Zero offset - scale only")
        func zeroOffset() throws {
            // Voltage sensor: scale=0.1, no offset
            let item = SensorItem(
                name: "Voltage",
                registers: [100],
                rule: .uint16,
                scale: 0.1,
                offset: 0.0,
            )
            // raw=2316 → (2316 - 0) * 0.1 = 231.6V
            let result = try converter.convert(registers: [2316], item: item)
            #expect((result * 10).rounded() == 2316)
        }

        @Test("Inverse flag negates value")
        func inverseFlag() throws {
            let item = SensorItem(
                name: "Power",
                registers: [100],
                rule: .int16,
                inverse: true,
            )
            let result = try converter.convert(registers: [500], item: item)
            #expect(result == -500.0)
        }
    }

    // MARK: - Range Filtering Tests (Raw Value)

    @Suite("Range Filtering (ha-solarman range)")
    struct RangeFilteringTests {
        let converter = RegisterConverter()

        @Test("Raw value within range passes")
        func withinRange() throws {
            let item = SensorItem(
                name: "Device MPPTs",
                registers: [0x0016],
                rule: .uint16,
                rangeMin: 257,
                rangeMax: nil,
                rangeDefault: 2,
            )
            // Raw value 260 >= 257, passes range check
            let result = try converter.convert(registers: [260], item: item)
            #expect(result == 260.0)
        }

        @Test("Raw value below minimum returns default")
        func belowMinimumReturnsDefault() throws {
            let item = SensorItem(
                name: "Device MPPTs",
                registers: [0x0016],
                rule: .uint16,
                rangeMin: 257,
                rangeMax: nil,
                rangeDefault: 2,
            )
            // Raw value 100 < 257, returns default=2
            let result = try converter.convert(registers: [100], item: item)
            #expect(result == 2.0)
        }

        @Test("Raw value above maximum returns default")
        func aboveMaximumReturnsDefault() throws {
            let item = SensorItem(
                name: "Timer Duration",
                registers: [0x003D],
                rule: .uint16,
                rangeMin: 0,
                rangeMax: 1000,
                rangeDefault: 0,
            )
            // Raw value 2000 > 1000, returns default=0
            let result = try converter.convert(registers: [2000], item: item)
            #expect(result == 0.0)
        }

        @Test("0xFFFF filtered by range returns default")
        func invalidValueFiltered() throws {
            // This is the critical case: inverter returns 0xFFFF for unavailable sensors
            let item = SensorItem(
                name: "Load Power",
                registers: [0x028D],
                rule: .uint16,
                rangeMin: 0,
                rangeMax: 50000,
                rangeDefault: nil, // No default = nil result
            )
            // Raw value 65535 > 50000, should be filtered
            let result = try? converter.convert(registers: [65535], item: item)
            #expect(result == nil)
        }

        @Test("Range with scale and offset applied after range check")
        func rangeCheckBeforeTransform() throws {
            // ha-solarman applies range to raw value BEFORE offset/scale
            let item = SensorItem(
                name: "DC Temperature",
                registers: [0x005A],
                rule: .uint16,
                scale: 0.1,
                offset: 1000.0,
                rangeMin: 900,
                rangeMax: 1500,
                rangeDefault: 1000,
            )
            // Raw 1259 is in range [900, 1500], then transform: (1259-1000)*0.1 = 25.9
            let result = try converter.convert(registers: [1259], item: item)
            #expect((result * 10).rounded() == 259)
        }
    }

    // MARK: - Validation Tests (Post-Transformation)

    @Suite("Validation (post-transformation)")
    struct ValidationTests {
        let converter = RegisterConverter()

        @Test("Value within range passes")
        func withinRange() throws {
            let item = SensorItem(
                name: "SOC",
                registers: [100],
                rule: .uint16,
                validationMin: 0,
                validationMax: 100,
            )
            let result = try converter.convert(registers: [85], item: item)
            #expect(result == 85.0)
        }

        @Test("Value below minimum throws")
        func belowMinimum() throws {
            let item = SensorItem(
                name: "SOC",
                registers: [100],
                rule: .int16,
                validationMin: 0,
                validationMax: 100,
            )
            #expect(throws: SensorError.valueOutOfRange(value: -10.0, min: 0, max: 100)) {
                try converter.convert(registers: [UInt16(bitPattern: -10)], item: item)
            }
        }

        @Test("Value above maximum throws")
        func aboveMaximum() throws {
            let item = SensorItem(
                name: "SOC",
                registers: [100],
                rule: .uint16,
                validationMin: 0,
                validationMax: 100,
            )
            #expect(throws: SensorError.valueOutOfRange(value: 150.0, min: 0, max: 100)) {
                try converter.convert(registers: [150], item: item)
            }
        }
    }

    // MARK: - Unsupported Rules

    @Suite("Unsupported Rules")
    struct UnsupportedTests {
        let converter = RegisterConverter()

        @Test("Computed rule throws unsupported")
        func computedUnsupported() throws {
            #expect(throws: SensorError.unsupportedRule(.computed)) {
                try converter.convertRaw(registers: [0], rule: .computed)
            }
        }

        @Test("ASCII rule throws unsupported for numeric conversion")
        func asciiUnsupported() throws {
            #expect(throws: SensorError.unsupportedRule(.ascii)) {
                try converter.convertRaw(registers: [0x4142], rule: .ascii)
            }
        }

        @Test("Raw rule throws unsupported")
        func rawUnsupported() throws {
            #expect(throws: SensorError.unsupportedRule(.raw)) {
                try converter.convertRaw(registers: [0x0000], rule: .raw)
            }
        }
    }

    // MARK: - Mask + Divide Tests

    @Suite("Mask and Divide")
    struct MaskDivideTests {
        let converter = RegisterConverter()

        @Test("Device MPPTs - mask 0x0F00, divide 256")
        func deviceMPPTs() throws {
            // Register 0x0016 = 0x0203 (2 MPPTs, 3 phases encoded)
            // mask 0x0F00 → 0x0200 = 512
            // divide 256 → 2
            let item = SensorItem(
                name: "Device MPPTs",
                registers: [0x0016],
                rule: .uint16,
                mask: 0x0F00,
                divide: 256,
            )
            let result = try converter.convert(registers: [0x0203], item: item)
            #expect(result == 2.0)
        }

        @Test("Device Phases - mask 0x000F only")
        func devicePhases() throws {
            // Register 0x0016 = 0x0203
            // mask 0x000F → 0x0003 = 3
            let item = SensorItem(
                name: "Device Phases",
                registers: [0x0016],
                rule: .uint16,
                mask: 0x000F,
            )
            let result = try converter.convert(registers: [0x0203], item: item)
            #expect(result == 3.0)
        }

        @Test("Mask applied before scale")
        func maskBeforeScale() throws {
            // raw = 0xFF00, mask 0xFF00 → 0xFF00 = 65280
            // scale 0.01 → 652.8
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                scale: 0.01,
                mask: 0xFF00,
            )
            let result = try converter.convert(registers: [0xFF00], item: item)
            #expect((result * 10).rounded() == 6528)
        }

        @Test("Divide applied after scale")
        func divideAfterScale() throws {
            // raw = 1000, scale 2.0 → 2000, divide 100 → 20
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                scale: 2.0,
                divide: 100,
            )
            let result = try converter.convert(registers: [1000], item: item)
            #expect(result == 20.0)
        }

        @Test("Divide uses integer division")
        func divideIntegerDivision() throws {
            // raw = 7, divide 3 → 2 (not 2.33...)
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                divide: 3,
            )
            let result = try converter.convert(registers: [7], item: item)
            #expect(result == 2.0)
        }

        @Test("Mask with zero clears value")
        func maskZero() throws {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                mask: 0x0000,
            )
            let result = try converter.convert(registers: [0xFFFF], item: item)
            #expect(result == 0.0)
        }

        @Test("Divide by 1 unchanged")
        func divideByOne() throws {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                divide: 1,
            )
            let result = try converter.convert(registers: [42], item: item)
            #expect(result == 42.0)
        }

        @Test("No mask or divide - unchanged")
        func noMaskNoDivide() throws {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
            )
            let result = try converter.convert(registers: [12345], item: item)
            #expect(result == 12345.0)
        }
    }

    // MARK: - Bit Extraction Tests

    @Suite("Bit Extraction")
    struct BitExtractionTests {
        let converter = RegisterConverter()

        @Test("Extract bit 0 (LSB)")
        func extractBit0() throws {
            // 0b1010 = 10, bit 0 → 0
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                bit: 0,
            )
            let result = try converter.convert(registers: [0b1010], item: item)
            #expect(result == 0.0)
        }

        @Test("Extract bit 1")
        func extractBit1() throws {
            // 0b1010 = 10, bit 1 → 1
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                bit: 1,
            )
            let result = try converter.convert(registers: [0b1010], item: item)
            #expect(result == 1.0)
        }

        @Test("Extract bit 3")
        func extractBit3() throws {
            // 0b1010 = 10, bit 3 → 1
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                bit: 3,
            )
            let result = try converter.convert(registers: [0b1010], item: item)
            #expect(result == 1.0)
        }

        @Test("Extract bit 15 (MSB of UInt16)")
        func extractBit15() throws {
            // 0x8000 = bit 15 set
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                bit: 15,
            )
            let result = try converter.convert(registers: [0x8000], item: item)
            #expect(result == 1.0)
        }

        @Test("Bit applied after mask")
        func bitAfterMask() throws {
            // value = 0xFF00, mask 0x0F00 → 0x0F00
            // bit 8 → (0x0F00 >> 8) & 1 = 0x0F & 1 = 1
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                mask: 0x0F00,
                bit: 8,
            )
            let result = try converter.convert(registers: [0xFF00], item: item)
            #expect(result == 1.0)
        }

        @Test("Bit extraction returns 0 or 1 only")
        func bitReturnsZeroOrOne() throws {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                bit: 0,
            )
            // Even with 0xFFFF, bit extraction returns only 0 or 1
            let result = try converter.convert(registers: [0xFFFF], item: item)
            #expect(result == 1.0)
        }

        @Test("No bit extraction - unchanged")
        func noBitExtraction() throws {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
            )
            let result = try converter.convert(registers: [0b1010], item: item)
            #expect(result == 10.0)
        }
    }

    // MARK: - Sign-Magnitude Tests

    @Suite("Sign-Magnitude (magnitude flag)")
    struct MagnitudeTests {
        let converter = RegisterConverter()

        @Test("Int16 positive value unchanged")
        func int16PositiveUnchanged() throws {
            // Positive values are the same in two's complement and sign-magnitude
            let item = SensorItem(
                name: "CT1 Current",
                registers: [0x0000],
                rule: .int16,
                magnitude: true,
            )
            let result = try converter.convert(registers: [1500], item: item)
            #expect(result == 1500.0)
        }

        @Test("Int16 sign-magnitude negative")
        func int16SignMagnitudeNegative() throws {
            // Sign-magnitude: 0x8001 = -1 (bit 15 = sign, bits 0-14 = 1)
            // Two's complement: 0x8001 = -32767
            let item = SensorItem(
                name: "CT1 Current",
                registers: [0x0000],
                rule: .int16,
                magnitude: true,
            )
            let result = try converter.convert(registers: [0x8001], item: item)
            #expect(result == -1.0)
        }

        @Test("Int16 sign-magnitude larger negative")
        func int16SignMagnitudeLargerNegative() throws {
            // Sign-magnitude: 0x8064 = -100 (bit 15 = sign, bits 0-14 = 100)
            let item = SensorItem(
                name: "CT1 Power",
                registers: [0x0000],
                rule: .int16,
                magnitude: true,
            )
            let result = try converter.convert(registers: [0x8064], item: item)
            #expect(result == -100.0)
        }

        @Test("Int16 sign-magnitude max positive")
        func int16SignMagnitudeMaxPositive() throws {
            // Sign-magnitude max positive: 0x7FFF = 32767
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .int16,
                magnitude: true,
            )
            let result = try converter.convert(registers: [0x7FFF], item: item)
            #expect(result == 32767.0)
        }

        @Test("Int16 sign-magnitude max negative")
        func int16SignMagnitudeMaxNegative() throws {
            // Sign-magnitude: 0xFFFF = -32767 (bit 15 = sign, bits 0-14 = 32767)
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .int16,
                magnitude: true,
            )
            let result = try converter.convert(registers: [0xFFFF], item: item)
            #expect(result == -32767.0)
        }

        @Test("Int16 magnitude false uses two's complement")
        func int16TwosComplement() throws {
            // Two's complement: 0x8001 = -32767
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .int16,
                magnitude: false,
            )
            let result = try converter.convert(registers: [0x8001], item: item)
            #expect(result == -32767.0)
        }

        @Test("Int32 sign-magnitude negative")
        func int32SignMagnitudeNegative() throws {
            // Sign-magnitude 32-bit: bit 31 = sign, bits 0-30 = magnitude
            // 0x80000001 = -1 in sign-magnitude
            // Stored as: [0x0001, 0x8000] (low word first)
            let item = SensorItem(
                name: "CT1 Active Power",
                registers: [0x0000, 0x0001],
                rule: .int32,
                magnitude: true,
            )
            let result = try converter.convert(registers: [0x0001, 0x8000], item: item)
            #expect(result == -1.0)
        }

        @Test("Int32 sign-magnitude larger negative")
        func int32SignMagnitudeLargerNegative() throws {
            // Sign-magnitude: 0x80001388 = -5000 (bit 31 = sign, bits 0-30 = 5000)
            // Stored as: [0x1388, 0x8000] (low word first)
            let item = SensorItem(
                name: "CT1 Power",
                registers: [0x0000, 0x0001],
                rule: .int32,
                magnitude: true,
            )
            let result = try converter.convert(registers: [0x1388, 0x8000], item: item)
            #expect(result == -5000.0)
        }

        @Test("Magnitude with scale")
        func magnitudeWithScale() throws {
            // Sign-magnitude: 0x8064 = -100, scale 0.001 → -0.1
            let item = SensorItem(
                name: "CT1 Current",
                registers: [0x0000],
                rule: .int16,
                scale: 0.001,
                magnitude: true,
            )
            let result = try converter.convert(registers: [0x8064], item: item)
            #expect((result * 10).rounded() == -1)
        }
    }

    // MARK: - String Edge Cases

    @Suite("String Edge Cases")
    struct StringEdgeCaseTests {
        let converter = RegisterConverter()

        @Test("Invalid UTF-8 bytes throw error")
        func invalidUTF8Bytes() throws {
            // 0xFF 0xFE is invalid UTF-8 sequence
            let registers: [UInt16] = [0xFFFE]
            #expect(throws: SensorError.self) {
                try converter.convertString(registers: registers)
            }
        }

        @Test("Valid ASCII with null in low byte")
        func nullInLowByte() throws {
            // 0x4100 = 'A' followed by null → stops at 'A'
            let registers: [UInt16] = [0x4100]
            let result = try converter.convertString(registers: registers)
            #expect(result == "A")
        }

        @Test("Long string - 10 registers")
        func longString() throws {
            // "ABCDEFGHIJKLMNOPQRST" (20 characters)
            let registers: [UInt16] = [
                0x4142, 0x4344, 0x4546, 0x4748, 0x494A, // ABCDEFGHIJ
                0x4B4C, 0x4D4E, 0x4F50, 0x5152, 0x5354, // KLMNOPQRST
            ]
            let result = try converter.convertString(registers: registers)
            #expect(result == "ABCDEFGHIJKLMNOPQRST")
        }

        @Test("Only high byte null - empty string")
        func highByteNull() throws {
            // 0x0041 = null in high byte, should stop immediately
            let registers: [UInt16] = [0x0041]
            let result = try converter.convertString(registers: registers)
            #expect(result == "")
        }

        @Test("Printable ASCII range accepted")
        func printableASCII() throws {
            // Space (0x20) to tilde (0x7E)
            let registers: [UInt16] = [0x207E, 0x217D]
            let result = try converter.convertString(registers: registers)
            #expect(result == " ~!}")
        }

        @Test("DEL character rejected")
        func delCharacterRejected() throws {
            // 0x7F is DEL control character
            let registers: [UInt16] = [0x417F]
            #expect(throws: SensorError.self) {
                try converter.convertString(registers: registers)
            }
        }
    }

    // MARK: - Time Edge Cases

    @Suite("Time Edge Cases")
    struct TimeEdgeCaseTests {
        let converter = RegisterConverter()

        @Test("Invalid hour 25 - still converts")
        func invalidHour25() {
            // 2500 → 25 hours, 0 minutes (invalid but we don't validate)
            let result = converter.convertTime(registers: [2500])
            #expect(result == "25:00")
        }

        @Test("Invalid minute 61 - still converts")
        func invalidMinute61() {
            // 1261 → 12 hours, 61 minutes (invalid but we don't validate)
            let result = converter.convertTime(registers: [1261])
            #expect(result == "12:61")
        }

        @Test("Empty registers returns nil")
        func emptyRegistersNil() {
            let result = converter.convertTime(registers: [])
            #expect(result == nil)
        }

        @Test("Large time value 9999")
        func largeTimeValue() {
            // 9999 → 99:99 (invalid but converted)
            let result = converter.convertTime(registers: [9999])
            #expect(result == "99:99")
        }

        @Test("Zero time - midnight")
        func zeroTimeMidnight() {
            let result = converter.convertTime(registers: [0])
            #expect(result == "00:00")
        }
    }

    // MARK: - Numeric Edge Cases

    @Suite("Numeric Edge Cases")
    struct NumericEdgeCaseTests {
        let converter = RegisterConverter()

        @Test("Very large scale factor")
        func veryLargeScale() throws {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                scale: 1_000_000.0,
            )
            // 1 * 1_000_000 = 1_000_000
            let result = try converter.convert(registers: [1], item: item)
            #expect(result == 1_000_000.0)
        }

        @Test("Very small scale factor")
        func verySmallScale() throws {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                scale: 0.000001,
            )
            // 1_000_000 * 0.000001 = 1.0
            let result = try converter.convert(registers: [10000], item: item)
            #expect((result * 100).rounded() == 1) // 0.01
        }

        @Test("Negative scale factor")
        func negativeScale() throws {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                scale: -1.0,
            )
            // 100 * -1 = -100
            let result = try converter.convert(registers: [100], item: item)
            #expect(result == -100.0)
        }

        @Test("Zero scale factor")
        func zeroScale() throws {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                scale: 0.0,
            )
            // 100 * 0 = 0
            let result = try converter.convert(registers: [100], item: item)
            #expect(result == 0.0)
        }

        @Test("Large offset subtraction")
        func largeOffsetSubtraction() throws {
            // Offset larger than raw value → negative result
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                scale: 1.0,
                offset: 10000,
            )
            // (100 - 10000) * 1.0 = -9900
            let result = try converter.convert(registers: [100], item: item)
            #expect(result == -9900.0)
        }

        @Test("UInt16 max value")
        func uint16MaxValue() throws {
            let result = try converter.convertRaw(
                registers: [UInt16.max],
                rule: .uint16,
            )
            #expect(result == 65535.0)
        }

        @Test("Int16 min value")
        func int16MinValue() throws {
            let result = try converter.convertRaw(
                registers: [UInt16(bitPattern: Int16.min)],
                rule: .int16,
            )
            #expect(result == -32768.0)
        }

        @Test("UInt32 max value")
        func uint32MaxValue() throws {
            let result = try converter.convertRaw(
                registers: [0xFFFF, 0xFFFF],
                rule: .uint32,
            )
            #expect(result == Double(UInt32.max))
        }
    }

    // MARK: - DateTime Tests (Rule 8)

    @Suite("DateTime (Rule 8)")
    struct DateTimeTests {
        let converter = RegisterConverter()

        @Test("3-register format - Dec 14, 2024 15:30:45")
        func threeRegisterFormat() {
            // Register 0: YY/MM = 24/12 → 0x180C
            // Register 1: DD/HH = 14/15 → 0x0E0F
            // Register 2: MM/SS = 30/45 → 0x1E2D
            let result = converter.convertDateTime(registers: [0x180C, 0x0E0F, 0x1E2D])
            #expect(result == "24/12/14 15:30:45")
        }

        @Test("3-register format - Jan 1, 2025 00:00:00")
        func threeRegisterMidnight() {
            // Register 0: YY/MM = 25/01 → 0x1901
            // Register 1: DD/HH = 01/00 → 0x0100
            // Register 2: MM/SS = 00/00 → 0x0000
            let result = converter.convertDateTime(registers: [0x1901, 0x0100, 0x0000])
            #expect(result == "25/01/01 00:00:00")
        }

        @Test("3-register format - high byte is first component")
        func threeRegisterHighByte() {
            // Verify high byte = YY, low byte = MM in register 0
            // 0x1907 = 25 (year), 7 (month) → July 2025
            let result = converter.convertDateTime(registers: [0x1907, 0x1510, 0x0000])
            #expect(result == "25/07/21 16:00:00")
        }

        @Test("6-register format - Dec 14, 2024 15:30:45")
        func sixRegisterFormat() {
            // Each register is a single component
            let result = converter.convertDateTime(registers: [24, 12, 14, 15, 30, 45])
            #expect(result == "24/12/14 15:30:45")
        }

        @Test("6-register format - Jan 1, 2025 00:00:00")
        func sixRegisterMidnight() {
            let result = converter.convertDateTime(registers: [25, 1, 1, 0, 0, 0])
            #expect(result == "25/01/01 00:00:00")
        }

        @Test("6-register format - single digit values padded")
        func sixRegisterPadded() {
            let result = converter.convertDateTime(registers: [25, 1, 5, 9, 5, 3])
            #expect(result == "25/01/05 09:05:03")
        }

        @Test("Insufficient registers returns nil")
        func insufficientRegisters() {
            // Only 2 registers, need at least 3
            let result = converter.convertDateTime(registers: [0x1901, 0x0100])
            #expect(result == nil)
        }

        @Test("Empty registers returns nil")
        func emptyRegisters() {
            let result = converter.convertDateTime(registers: [])
            #expect(result == nil)
        }
    }

    let converter = RegisterConverter()
}
