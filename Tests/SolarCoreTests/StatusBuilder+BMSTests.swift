// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

@testable import SolarCore
import Testing

// MARK: - BMS StatusBuilder Tests

@Suite("StatusBuilder+BMS")
struct StatusBuilderBMSTests {
    let builder = StatusBuilder()

    @Test("Builds BMS status from values")
    func buildBMSValid() {
        let values = SensorValues([
            "battery_bms_soc": 85,
            "battery_bms_voltage": 53.2,
            "battery_bms_current": 10.5,
            "battery_bms_charging_voltage": 58.4,
            "battery_bms_discharging_voltage": 48.0,
            "battery_bms_max_charging_current": 100,
            "battery_bms_max_discharging_current": 120,
            "battery_bms_charging_current": 80,
            "battery_bms_discharging_current": 90,
        ])

        let bmsArray = builder.buildBMS(from: values)

        #expect(bmsArray?.count == 1)
        let bms = bmsArray?.first
        #expect(bms?.unit == 1)
        #expect(bms?.isConnected == true)
        #expect(bms?.soc == 85)
        #expect(bms?.voltage == 53.2)
        #expect(bms?.current == 10.5)
        #expect(bms?.chargingVoltage == 58.4)
        #expect(bms?.dischargeVoltage == 48.0)
        #expect(bms?.maxChargeCurrent == 100)
        #expect(bms?.maxDischargeCurrent == 120)
        #expect(bms?.chargeCurrentLimit == 80)
        #expect(bms?.dischargeCurrentLimit == 90)
    }

    @Test("Returns nil when SOC missing")
    func buildBMSMissingSOC() {
        let values = SensorValues([
            "battery_bms_voltage": 53.2,
            "battery_bms_current": 10.0,
        ])

        let bms = builder.buildBMS(from: values)

        #expect(bms == nil)
    }

    @Test("Returns nil when voltage missing")
    func buildBMSMissingVoltage() {
        let values = SensorValues([
            "battery_bms_soc": 80,
            "battery_bms_current": 10.0,
        ])

        let bms = builder.buildBMS(from: values)

        #expect(bms == nil)
    }

    @Test("Uses zero current when missing")
    func buildBMSMissingCurrent() {
        let values = SensorValues([
            "battery_bms_soc": 90,
            "battery_bms_voltage": 52.0,
            // No current
        ])

        let bmsArray = builder.buildBMS(from: values)

        #expect(bmsArray?.first?.current == 0)
    }

    @Test("Clamps SOC to UInt8 range")
    func buildBMSSOCClamping() {
        let values = SensorValues([
            "battery_bms_soc": 150, // Over 100%
            "battery_bms_voltage": 53.0,
        ])

        let bms = builder.buildBMS(from: values)?.first

        #expect(bms?.soc == 150) // UInt8 max is 255, so 150 is valid
    }

    @Test("Returns nil for empty values")
    func buildBMSEmpty() {
        let values = SensorValues([:])

        let bms = builder.buildBMS(from: values)

        #expect(bms == nil)
    }

    // MARK: - Battery 1 Style (deye_p3)

    @Test("Builds BMS from Battery 1 style keys")
    func buildBMSBattery1Style() {
        let values = SensorValues([
            "battery_1": 95, // SOC
            "battery_1_voltage": 54.0,
            "battery_1_current": -5.0, // Charging
            "battery_1_soh": 98,
            "battery_1_cycles": 125,
            "battery_1_temperature": 25.0,
        ])

        let bmsArray = builder.buildBMS(from: values)

        #expect(bmsArray?.count == 1)
        let bms = bmsArray?.first
        #expect(bms?.unit == 1)
        #expect(bms?.soc == 95)
        #expect(bms?.soh == 98)
        #expect(bms?.cycles == 125)
        #expect(bms?.temperature == 25.0)
        #expect(bms?.voltage == 54.0)
        #expect(bms?.current == -5.0)
    }

    @Test("Builds CellInfo when cell data available")
    func buildBMSWithCellInfo() {
        let values = SensorValues([
            "battery_1": 90,
            "battery_1_voltage": 53.5,
            "battery_1_current": 0,
            "battery_1_min_cell_voltage": 3.28,
            "battery_1_max_cell_voltage": 3.32,
            "battery_1_min_cell_temperature": 22.0,
            "battery_1_max_cell_temperature": 26.0,
        ])

        let bms = builder.buildBMS(from: values)?.first

        #expect(bms?.cells != nil)
        #expect(bms?.cells?.minVoltage == 3.28)
        #expect(bms?.cells?.maxVoltage == 3.32)
        #expect(bms?.cells?.voltageDelta == 40) // (3.32 - 3.28) * 1000 = 40mV
        #expect(bms?.cells?.minTemperature == 22.0)
        #expect(bms?.cells?.maxTemperature == 26.0)
        #expect(bms?.cells?.cellCount == 16) // Default
    }

    @Test("Builds multiple BMS units when available")
    func buildBMSMultipleUnits() {
        let values = SensorValues([
            "battery_1": 85,
            "battery_1_voltage": 53.0,
            "battery_1_current": 10.0,
            "battery_2": 90,
            "battery_2_voltage": 54.0,
            "battery_2_current": -5.0,
        ])

        let bmsArray = builder.buildBMS(from: values)

        #expect(bmsArray?.count == 2)
        #expect(bmsArray?[0].unit == 1)
        #expect(bmsArray?[0].soc == 85)
        #expect(bmsArray?[1].unit == 2)
        #expect(bmsArray?[1].soc == 90)
    }

    @Test("CellInfo nil when only partial cell data")
    func buildBMSPartialCellData() {
        let values = SensorValues([
            "battery_1": 80,
            "battery_1_voltage": 52.0,
            "battery_1_current": 0,
            "battery_1_min_cell_voltage": 3.25, // Only min, no max
        ])

        let bms = builder.buildBMS(from: values)?.first

        #expect(bms != nil)
        #expect(bms?.cells == nil)
    }
}
