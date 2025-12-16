// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

@testable import SolarCore
import Testing

// MARK: - PV StatusBuilder Tests

@Suite("StatusBuilder+PV")
struct StatusBuilderPVTests {
    let builder = StatusBuilder()

    @Test("Builds PV status with multiple strings")
    func buildPVMultipleStrings() {
        let values = SensorValues([
            "pv1_voltage": 350.0,
            "pv1_power": 2500,
            "pv2_voltage": 340.0,
            "pv2_power": 2300,
            "daily_production": 35.6,
        ])

        let pv = builder.buildPV(from: values)

        #expect(pv?.strings.count == 2)
        #expect(pv?.power == 4800) // Sum of strings
        #expect(pv?.dailyProduction == 35.6)

        let pv1 = pv?.strings.first { $0.id == 1 }
        #expect(pv1?.voltage == 350.0)
        #expect(pv1?.power == 2500)
    }

    @Test("Uses total_pv_power when available")
    func buildPVTotalPower() {
        let values = SensorValues([
            "pv1_power": 3000,
            "pv2_power": 2000,
            "total_pv_power": 5500, // Explicit total (may differ due to losses)
        ])

        let pv = builder.buildPV(from: values)

        #expect(pv?.power == 5500) // Uses explicit total
    }

    @Test("Returns nil when no values")
    func buildPVEmpty() {
        let values = SensorValues([:])

        let pv = builder.buildPV(from: values)

        #expect(pv == nil)
    }

    // MARK: - ha-solarman Naming (today_* keys)

    @Test("Uses today_production alternative (ha-solarman)")
    func buildPVTodayProduction() {
        // ha-solarman: "Today Production" → "today_production"
        let values = SensorValues([
            "pv1_power": 2000,
            "today_production": 18.5,
        ])

        let pv = builder.buildPV(from: values)

        #expect(pv?.dailyProduction == 18.5)
    }

    @Test("Prefers daily_production over today_production")
    func buildPVDailyProductionPriority() {
        // daily_production should have higher priority
        let values = SensorValues([
            "pv1_power": 2000,
            "daily_production": 20.0,
            "today_production": 18.5, // Should be ignored
        ])

        let pv = builder.buildPV(from: values)

        #expect(pv?.dailyProduction == 20.0)
    }
}
