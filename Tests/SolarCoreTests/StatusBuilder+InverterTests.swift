// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

@testable import SolarCore
import Testing

// MARK: - Inverter StatusBuilder Tests

@Suite("StatusBuilder+Inverter")
struct StatusBuilderInverterTests {
    let builder = StatusBuilder()

    @Test("Extracts serial number from ASCII sensor")
    func serialNumberExtraction() {
        // "AB12" = 0x4142 0x3132
        let registers: [UInt16: UInt16] = [
            100: 0x4142,
            101: 0x3132,
        ]
        let items = [
            SensorItem(
                name: "Serial Number",
                registers: [100, 101],
                rule: .ascii,
            ),
        ]

        let inverter = builder.buildInverter(from: registers, items: items)

        #expect(inverter?.serialNumber == "AB12")
    }

    @Test("Returns nil serial for invalid UTF-8")
    func serialNumberInvalidUTF8() {
        // Invalid UTF-8 sequence (0xFF 0xFE)
        let registers: [UInt16: UInt16] = [
            100: 0xFFFE,
        ]
        let items = [
            SensorItem(
                name: "Serial Number",
                registers: [100],
                rule: .ascii,
            ),
        ]

        let inverter = builder.buildInverter(from: registers, items: items)

        #expect(inverter?.serialNumber == nil)
    }

    @Test("Maps status Standby from lookup")
    func statusStandby() {
        let registers: [UInt16: UInt16] = [
            500: 0, // Standby
        ]
        let items = [
            SensorItem(
                name: "Device State",
                registers: [500],
                rule: .uint16,
                lookup: [
                    LookupEntry(key: 0, value: "Standby"),
                    LookupEntry(key: 1, value: "Running"),
                ],
            ),
        ]

        let inverter = builder.buildInverter(from: registers, items: items)

        #expect(inverter?.status == .standby)
    }

    @Test("Maps status Running from lookup")
    func statusRunning() {
        let registers: [UInt16: UInt16] = [
            500: 1,
        ]
        let items = [
            SensorItem(
                name: "Running Status",
                registers: [500],
                rule: .uint16,
                lookup: [
                    LookupEntry(key: 0, value: "Stand-by"),
                    LookupEntry(key: 1, value: "Normal"),
                ],
            ),
        ]

        let inverter = builder.buildInverter(from: registers, items: items)

        #expect(inverter?.status == .running)
    }

    @Test("Maps status Fault from lookup")
    func statusFault() {
        let registers: [UInt16: UInt16] = [
            500: 2,
        ]
        let items = [
            SensorItem(
                name: "Device State",
                registers: [500],
                rule: .uint16,
                lookup: [
                    LookupEntry(key: 0, value: "Standby"),
                    LookupEntry(key: 1, value: "Running"),
                    LookupEntry(key: 2, value: "Fault"),
                ],
            ),
        ]

        let inverter = builder.buildInverter(from: registers, items: items)

        #expect(inverter?.status == .fault)
    }

    @Test("Returns unknown status for missing lookup")
    func statusUnknown() {
        let registers: [UInt16: UInt16] = [
            500: 99, // Unknown value
        ]
        let items = [
            SensorItem(
                name: "Device State",
                registers: [500],
                rule: .uint16,
                lookup: [
                    LookupEntry(key: 0, value: "Standby"),
                ],
            ),
        ]

        let inverter = builder.buildInverter(from: registers, items: items)

        #expect(inverter?.status == .unknown)
    }

    @Test("Extracts DC temperature")
    func dcTemperatureExtraction() {
        let registers: [UInt16: UInt16] = [
            90: 1259, // (1259 - 1000) * 0.1 = 25.9°C
        ]
        let items = [
            SensorItem(
                name: "DC Temperature",
                registers: [90],
                rule: .uint16,
                scale: 0.1,
                offset: 1000,
            ),
        ]

        let inverter = builder.buildInverter(from: registers, items: items)

        #expect(inverter?.dcTemperature != nil)
        if let temp = inverter?.dcTemperature {
            #expect((temp * 10).rounded() == 259)
        }
    }

    @Test("Extracts AC temperature with alternative name")
    func acTemperatureExtraction() {
        let registers: [UInt16: UInt16] = [
            91: 1300, // (1300 - 1000) * 0.1 = 30.0°C
        ]
        let items = [
            SensorItem(
                name: "Inverter AC Temperature",
                registers: [91],
                rule: .uint16,
                scale: 0.1,
                offset: 1000,
            ),
        ]

        let inverter = builder.buildInverter(from: registers, items: items)

        #expect(inverter?.acTemperature == 30.0)
    }

    @Test("Returns nil when no values available")
    func missingFieldsReturnsNil() {
        let registers: [UInt16: UInt16] = [:]
        let items: [SensorItem] = []

        let inverter = builder.buildInverter(from: registers, items: items)

        #expect(inverter == nil)
    }

    @Test("Device Serial Number alternative name works")
    func deviceSerialNumberAlternative() {
        let registers: [UInt16: UInt16] = [
            200: 0x5859, // "XY"
        ]
        let items = [
            SensorItem(
                name: "Device Serial Number",
                registers: [200],
                rule: .ascii,
            ),
        ]

        let inverter = builder.buildInverter(from: registers, items: items)

        #expect(inverter?.serialNumber == "XY")
    }

    @Test("Extracts device model from lookup")
    func deviceModelExtraction() {
        let registers: [UInt16: UInt16] = [
            0: 0x0005, // LV 3-Phase Hybrid Inverter
        ]
        let items = [
            SensorItem(
                name: "Device",
                registers: [0],
                rule: .uint16,
                lookup: [
                    LookupEntry(key: 0x0005, value: "LV 3-Phase Hybrid Inverter"),
                ],
            ),
        ]

        let inverter = builder.buildInverter(from: registers, items: items)

        #expect(inverter?.model == "LV 3-Phase Hybrid Inverter")
    }

    @Test("Extracts firmware version")
    func firmwareVersionExtraction() {
        // Version rule: nibbles → "1.2.3.4" (hex, so 0x1234 → "1.2.3.4")
        let registers: [UInt16: UInt16] = [
            10: 0x1234,
        ]
        let items = [
            SensorItem(
                name: "Device Control Board Firmware Version",
                registers: [10],
                rule: .version,
            ),
        ]

        let inverter = builder.buildInverter(from: registers, items: items)

        // Version is extracted as hex nibbles: 0x1234 → "1.2.3.4"
        #expect(inverter?.firmwareVersion == "1.2.3.4")
    }

    // MARK: - Alarms & Faults

    @Test("Extracts single alarm from bit lookup")
    func singleAlarmExtraction() {
        // Bit 1 set = "Fan failure"
        let registers: [UInt16: UInt16] = [
            0x0229: 0x0002, // Bit 1 set
        ]
        let items = [
            SensorItem(
                name: "Device Alarm",
                registers: [0x0229],
                rule: .uint16,
                lookup: [
                    LookupEntry(key: .bit(0), value: "OK"),
                    LookupEntry(key: .bit(1), value: "Fan failure"),
                    LookupEntry(key: .bit(2), value: "Grid phase failure"),
                ],
            ),
        ]

        let inverter = builder.buildInverter(from: registers, items: items)

        #expect(inverter?.alarms.count == 1)
        #expect(inverter?.alarms.first?.bit == 1)
        #expect(inverter?.alarms.first?.description == "Fan failure")
    }

    @Test("Extracts multiple alarms from bit lookup")
    func multipleAlarmsExtraction() {
        // Bits 1 and 2 set
        let registers: [UInt16: UInt16] = [
            0x0229: 0x0006, // Bits 1 and 2 set
        ]
        let items = [
            SensorItem(
                name: "Device Alarm",
                registers: [0x0229],
                rule: .uint16,
                lookup: [
                    LookupEntry(key: .bit(0), value: "OK"),
                    LookupEntry(key: .bit(1), value: "Fan failure"),
                    LookupEntry(key: .bit(2), value: "Grid phase failure"),
                ],
            ),
        ]

        let inverter = builder.buildInverter(from: registers, items: items)

        #expect(inverter?.alarms.count == 2)
        let bits = inverter?.alarms.map(\.bit) ?? []
        #expect(bits.contains(1))
        #expect(bits.contains(2))
    }

    @Test("Returns empty alarms when raw value is zero")
    func noAlarmsWhenZero() {
        let registers: [UInt16: UInt16] = [
            0x0229: 0x0000,
        ]
        let items = [
            SensorItem(
                name: "Device Alarm",
                registers: [0x0229],
                rule: .uint16,
                lookup: [
                    LookupEntry(key: .bit(1), value: "Fan failure"),
                ],
            ),
        ]

        let inverter = builder.buildInverter(from: registers, items: items)

        #expect(inverter?.alarms.isEmpty == true)
    }

    @Test("Extracts faults from multi-register sensor (64-bit)")
    func faultsMultiRegisterExtraction() {
        // 4 registers, bit 6 set in first register (LSW in LE order)
        let registers: [UInt16: UInt16] = [
            0x022A: 0x0040, // Bit 6 set
            0x022B: 0x0000,
            0x022C: 0x0000,
            0x022D: 0x0000,
        ]
        let items = [
            SensorItem(
                name: "Device Fault",
                registers: [0x022A, 0x022B, 0x022C, 0x022D],
                rule: .uint16,
                lookup: [
                    LookupEntry(key: .bit(0), value: "DC/DC soft start fault"),
                    LookupEntry(key: .bit(6), value: "Over-current fault"),
                ],
            ),
        ]

        let inverter = builder.buildInverter(from: registers, items: items)

        #expect(inverter?.faults.count == 1)
        #expect(inverter?.faults.first?.bit == 6)
        #expect(inverter?.faults.first?.description == "Over-current fault")
    }

    @Test("Extracts fault from high bit in multi-register")
    func faultHighBitExtraction() {
        // Bit 17 set = second register bit 1 (LE: first reg is LSW)
        let registers: [UInt16: UInt16] = [
            0x022A: 0x0000,
            0x022B: 0x0002, // Bit 1 of second register = bit 17 overall
        ]
        let items = [
            SensorItem(
                name: "Device Fault",
                registers: [0x022A, 0x022B],
                rule: .uint16,
                lookup: [
                    LookupEntry(key: .bit(17), value: "PV voltage fault"),
                ],
            ),
        ]

        let inverter = builder.buildInverter(from: registers, items: items)

        #expect(inverter?.faults.count == 1)
        #expect(inverter?.faults.first?.bit == 17)
        #expect(inverter?.faults.first?.description == "PV voltage fault")
    }

    // MARK: - Device Configuration

    @Test("Extracts rated power")
    func ratedPowerExtraction() {
        // Rule 4 (S32), scale 0.1: 120000 * 0.1 = 12000W
        // 120000 = 0x1D4C0
        // CDAB order: registers[0] = low word (0xD4C0), registers[1] = high word (0x0001)
        let registers: [UInt16: UInt16] = [
            0x0014: 0xD4C0, // Low word
            0x0015: 0x0001, // High word
        ]
        let items = [
            SensorItem(
                name: "Device Rated Power",
                registers: [0x0014, 0x0015],
                rule: .int32,
                scale: 0.1,
            ),
        ]

        let inverter = builder.buildInverter(from: registers, items: items)

        #expect(inverter?.ratedPower == 12000)
    }

    @Test("Extracts MPPT count with mask and divide")
    func mpptCountExtraction() {
        // Register 0x0016 = 0x0203: mask 0x0F00 = 0x0200, divide 256 = 2
        let registers: [UInt16: UInt16] = [
            0x0016: 0x0203,
        ]
        let items = [
            SensorItem(
                name: "Device MPPTs",
                registers: [0x0016],
                rule: .uint16,
                mask: 0x0F00,
                divide: 256,
            ),
        ]

        let inverter = builder.buildInverter(from: registers, items: items)

        #expect(inverter?.mpptCount == 2)
    }

    @Test("Extracts phase count with mask")
    func phaseCountExtraction() {
        // Register 0x0016 = 0x0203: mask 0x000F = 0x0003 = 3 phases
        let registers: [UInt16: UInt16] = [
            0x0016: 0x0203,
        ]
        let items = [
            SensorItem(
                name: "Device Phases",
                registers: [0x0016],
                rule: .uint16,
                mask: 0x000F,
            ),
        ]

        let inverter = builder.buildInverter(from: registers, items: items)

        #expect(inverter?.phaseCount == 3)
    }

    @Test("Device configuration fields are nil when not present")
    func deviceConfigFieldsNil() {
        let registers: [UInt16: UInt16] = [
            100: 0x4142, // Just serial number
        ]
        let items = [
            SensorItem(
                name: "Serial Number",
                registers: [100],
                rule: .ascii,
            ),
        ]

        let inverter = builder.buildInverter(from: registers, items: items)

        #expect(inverter?.serialNumber == "AB")
        #expect(inverter?.ratedPower == nil)
        #expect(inverter?.mpptCount == nil)
        #expect(inverter?.phaseCount == nil)
    }
}
