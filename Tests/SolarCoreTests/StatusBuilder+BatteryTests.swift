// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

@testable import SolarCore
import Testing

// MARK: - Battery StatusBuilder Tests

@Suite("StatusBuilder+Battery")
struct StatusBuilderBatteryTests {
    let builder = StatusBuilder()

    @Test("Builds battery status from valid values")
    func buildBatteryValid() {
        let values = SensorValues([
            "battery_soc": 85,
            "battery_voltage": 51.2,
            "battery_power": -1500,
            "battery_temperature": 25.0,
        ])

        let battery = builder.buildBattery(from: values)

        #expect(battery?.soc == 85)
        #expect(battery?.voltage == 51.2)
        #expect(battery?.power == -1500)
        #expect(battery?.temperature == 25.0)
    }

    @Test("Returns nil when required fields missing")
    func buildBatteryMissingRequired() {
        let values = SensorValues([
            "battery_soc": 85,
            // Missing voltage and power
        ])

        let battery = builder.buildBattery(from: values)

        #expect(battery == nil)
    }

    @Test("Calculates current from power/voltage when missing")
    func buildBatteryCalculatedCurrent() {
        let values = SensorValues([
            "battery_soc": 80,
            "battery_voltage": 50.0,
            "battery_power": 1000,
            // No battery_current - should calculate
        ])

        let battery = builder.buildBattery(from: values)

        #expect(battery?.current == 20.0) // 1000W / 50V = 20A
    }

    @Test("Handles alternative field names")
    func buildBatteryAlternativeNames() {
        let values = SensorValues([
            "battery_soc": 75,
            "battery_voltage": 48.0,
            "battery_power": 500,
            "daily_battery_charge": 10.5, // Alternative name
            "total_battery_discharge": 1500.0,
        ])

        let battery = builder.buildBattery(from: values)

        #expect(battery?.dailyCharge == 10.5)
        #expect(battery?.totalDischarge == 1500.0)
    }

    @Test("Uses 'battery' as alternative SOC key (deye_p3)")
    func buildBatteryAlternativeSOC() {
        // deye_p3 uses "Battery" (not "Battery SOC") which normalizes to "battery"
        let values = SensorValues([
            "battery": 95, // Alternative key for SOC
            "battery_voltage": 53.28,
            "battery_power": 9,
        ])

        let battery = builder.buildBattery(from: values)

        #expect(battery?.soc == 95)
        #expect(battery?.voltage == 53.28)
        #expect(battery?.power == 9)
    }

    // MARK: - ha-solarman Naming (today_* keys)

    @Test("Uses today_battery_charge alternative (ha-solarman)")
    func buildBatteryTodayCharge() {
        // ha-solarman: "Today Battery Charge" → "today_battery_charge"
        let values = SensorValues([
            "battery_soc": 80,
            "battery_voltage": 52.0,
            "battery_power": 500,
            "today_battery_charge": 15.5,
        ])

        let battery = builder.buildBattery(from: values)

        #expect(battery?.dailyCharge == 15.5)
    }

    @Test("Uses today_battery_discharge alternative (ha-solarman)")
    func buildBatteryTodayDischarge() {
        // ha-solarman: "Today Battery Discharge" → "today_battery_discharge"
        let values = SensorValues([
            "battery_soc": 80,
            "battery_voltage": 52.0,
            "battery_power": -500,
            "today_battery_discharge": 8.2,
        ])

        let battery = builder.buildBattery(from: values)

        #expect(battery?.dailyDischarge == 8.2)
    }
}
