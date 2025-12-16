// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

@testable import SolarCore
import Testing

// MARK: - Load StatusBuilder Tests

@Suite("StatusBuilder+Load")
struct StatusBuilderLoadTests {
    let builder = StatusBuilder()

    @Test("Builds load status from values")
    func buildLoadValid() {
        let values = SensorValues([
            "load_power": 2500,
            "daily_load_consumption": 18.3,
            "total_load_consumption": 5432.1,
        ])

        let load = builder.buildLoad(from: values)

        #expect(load?.power == 2500)
        #expect(load?.dailyConsumption == 18.3)
        #expect(load?.totalConsumption == 5432.1)
    }

    @Test("Returns nil when power missing")
    func buildLoadMissingPower() {
        let values = SensorValues([
            "daily_load_consumption": 10.0,
        ])

        let load = builder.buildLoad(from: values)

        #expect(load == nil)
    }

    @Test("Uses total_load_power alternative")
    func buildLoadTotalPower() {
        let values = SensorValues([
            "total_load_power": 3500, // Alternative name
        ])

        let load = builder.buildLoad(from: values)

        #expect(load?.power == 3500)
    }

    @Test("Builds three-phase load status")
    func buildLoadThreePhase() {
        let values = SensorValues([
            "load_power": 2100,
            "load_l1_power": 700,
            "load_l2_power": 800,
            "load_l3_power": 600,
        ])

        let load = builder.buildLoad(from: values)

        #expect(load?.power == 2100)
        #expect(load?.phases?.count == 3)
        #expect(load?.phases?[0].phase == .l1)
        #expect(load?.phases?[0].power == 700)
        #expect(load?.phases?[1].phase == .l2)
        #expect(load?.phases?[1].power == 800)
        #expect(load?.phases?[2].phase == .l3)
        #expect(load?.phases?[2].power == 600)
    }

    @Test("Single-phase load has no phases array")
    func buildLoadSinglePhase() {
        let values = SensorValues([
            "load_power": 1500,
        ])

        let load = builder.buildLoad(from: values)

        #expect(load?.power == 1500)
        #expect(load?.phases == nil)
    }

    @Test("Partial phases (L1 and L2 only)")
    func buildLoadPartialPhases() {
        let values = SensorValues([
            "load_power": 1200,
            "load_l1_power": 500,
            "load_l2_power": 700,
        ])

        let load = builder.buildLoad(from: values)

        #expect(load?.power == 1200)
        #expect(load?.phases?.count == 2)
        #expect(load?.phases?[0].phase == .l1)
        #expect(load?.phases?[1].phase == .l2)
    }

    // MARK: - ha-solarman Naming (today_* keys)

    @Test("Uses today_load_consumption alternative (ha-solarman)")
    func buildLoadTodayConsumption() {
        // ha-solarman: "Today Load Consumption" → "today_load_consumption"
        let values = SensorValues([
            "load_power": 1500,
            "today_load_consumption": 22.8,
        ])

        let load = builder.buildLoad(from: values)

        #expect(load?.dailyConsumption == 22.8)
    }

    @Test("Prefers daily_load_consumption over today_load_consumption")
    func buildLoadDailyConsumptionPriority() {
        // daily_load_consumption should have higher priority
        let values = SensorValues([
            "load_power": 1500,
            "daily_load_consumption": 25.0,
            "today_load_consumption": 22.8, // Should be ignored
        ])

        let load = builder.buildLoad(from: values)

        #expect(load?.dailyConsumption == 25.0)
    }

    // MARK: - Load Output Measurements (Voltage/Current)

    @Test("Builds load phases with voltage and current")
    func buildLoadPhasesWithVoltage() {
        let values = SensorValues([
            "load_power": 2100,
            "load_l1_power": 700,
            "load_l1_voltage": 230.5,
            "output_l1_current": 3.04,
            "load_l2_power": 800,
            "load_l2_voltage": 231.0,
            "output_l2_current": 3.46,
            "load_l3_power": 600,
            "load_l3_voltage": 229.0,
            "output_l3_current": 2.62,
        ])

        let load = builder.buildLoad(from: values)

        #expect(load?.phases?.count == 3)

        let l1 = load?.phases?.first { $0.phase == .l1 }
        #expect(l1?.power == 700)
        #expect(l1?.voltage == 230.5)
        #expect(l1?.current == 3.04)

        let l2 = load?.phases?.first { $0.phase == .l2 }
        #expect(l2?.power == 800)
        #expect(l2?.voltage == 231.0)
        #expect(l2?.current == 3.46)

        let l3 = load?.phases?.first { $0.phase == .l3 }
        #expect(l3?.power == 600)
        #expect(l3?.voltage == 229.0)
        #expect(l3?.current == 2.62)
    }

    @Test("Load phases without voltage/current are nil")
    func buildLoadPhasesNoVoltage() {
        let values = SensorValues([
            "load_power": 1500,
            "load_l1_power": 1500,
            // No voltage or current
        ])

        let load = builder.buildLoad(from: values)

        #expect(load?.phases?.first?.voltage == nil)
        #expect(load?.phases?.first?.current == nil)
    }

    @Test("Partial voltage/current (only some phases have it)")
    func buildLoadPartialVoltage() {
        let values = SensorValues([
            "load_power": 2000,
            "load_l1_power": 1000,
            "load_l1_voltage": 230.0,
            // L1 has voltage, no current
            "load_l2_power": 1000,
            "output_l2_current": 4.3,
            // L2 has current, no voltage
        ])

        let load = builder.buildLoad(from: values)

        #expect(load?.phases?.count == 2)

        let l1 = load?.phases?.first { $0.phase == .l1 }
        #expect(l1?.voltage == 230.0)
        #expect(l1?.current == nil)

        let l2 = load?.phases?.first { $0.phase == .l2 }
        #expect(l2?.voltage == nil)
        #expect(l2?.current == 4.3)
    }

    @Test("Uses load_l*_current primary key (deye_hybrid naming)")
    func buildLoadCurrentPrimaryKey() {
        // deye_hybrid uses "Load L1 Current" → "load_l1_current"
        let values = SensorValues([
            "load_power": 1500,
            "load_l1_power": 1500,
            "load_l1_voltage": 230.0,
            "load_l1_current": 6.52, // Primary key
        ])

        let load = builder.buildLoad(from: values)

        let l1 = load?.phases?.first { $0.phase == .l1 }
        #expect(l1?.current == 6.52)
    }
}
