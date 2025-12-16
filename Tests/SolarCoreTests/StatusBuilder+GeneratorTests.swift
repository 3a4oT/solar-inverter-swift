// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

@testable import SolarCore
import Testing

// MARK: - Generator StatusBuilder Tests

@Suite("StatusBuilder+Generator")
struct StatusBuilderGeneratorTests {
    let builder = StatusBuilder()

    @Test("Builds generator status from values")
    func buildGeneratorValid() {
        let values = SensorValues([
            "generator_power": 3000,
            "daily_generator_production": 25.0,
            "total_generator_production": 1500.0,
        ])

        let generator = builder.buildGenerator(from: values)

        #expect(generator?.power == 3000)
        #expect(generator?.dailyProduction == 25.0)
        #expect(generator?.totalProduction == 1500.0)
    }

    @Test("Returns nil when power missing")
    func buildGeneratorMissingPower() {
        let values = SensorValues([
            "daily_generator_production": 10.0,
        ])

        let generator = builder.buildGenerator(from: values)

        #expect(generator == nil)
    }

    @Test("Uses total_generator_power alternative")
    func buildGeneratorAlternativePower() {
        let values = SensorValues([
            "total_generator_power": 5000,
        ])

        let generator = builder.buildGenerator(from: values)

        #expect(generator?.power == 5000)
    }

    @Test("Uses generator_energy___today alternative (ha-solarman naming)")
    func buildGeneratorHaSolarmanNaming() {
        // "Generator Energy - today" normalizes to "generator_energy___today"
        let values = SensorValues([
            "generator_power": 2000,
            "generator_energy___today": 15.5,
            "generator_energy": 800.0,
        ])

        let generator = builder.buildGenerator(from: values)

        #expect(generator?.dailyProduction == 15.5)
        #expect(generator?.totalProduction == 800.0)
    }

    @Test("Builds three-phase generator status")
    func buildGeneratorThreePhase() {
        let values = SensorValues([
            "generator_power": 6000,
            "generator_l1_voltage": 230.0,
            "generator_l1_power": 2000,
            "generator_l2_voltage": 231.0,
            "generator_l2_power": 2000,
            "generator_l3_voltage": 229.0,
            "generator_l3_power": 2000,
        ])

        let generator = builder.buildGenerator(from: values)

        #expect(generator?.power == 6000)
        #expect(generator?.phases.count == 3)
        #expect(generator?.phases[0].phase == .l1)
        #expect(generator?.phases[0].voltage == 230.0)
        #expect(generator?.phases[0].power == 2000)
        #expect(generator?.phases[1].phase == .l2)
        #expect(generator?.phases[2].phase == .l3)
    }

    @Test("Handles negative power (converts to absolute)")
    func buildGeneratorNegativePower() {
        let values = SensorValues([
            "generator_power": -1500,
        ])

        let generator = builder.buildGenerator(from: values)

        #expect(generator?.power == 1500) // abs()
    }

    @Test("Returns nil for empty values")
    func buildGeneratorEmpty() {
        let values = SensorValues([:])

        let generator = builder.buildGenerator(from: values)

        #expect(generator == nil)
    }

    // MARK: - isRunning Tests

    @Test("isRunning true when power > 0")
    func buildGeneratorIsRunningTrue() {
        let values = SensorValues([
            "generator_power": 3000,
        ])

        let generator = builder.buildGenerator(from: values)

        #expect(generator?.isRunning == true)
    }

    @Test("isRunning false when power is 0")
    func buildGeneratorIsRunningFalse() {
        let values = SensorValues([
            "generator_power": 0,
        ])

        let generator = builder.buildGenerator(from: values)

        #expect(generator?.isRunning == false)
    }

    @Test("isRunning true for negative power (after abs)")
    func buildGeneratorIsRunningNegativePower() {
        let values = SensorValues([
            "generator_power": -2500,
        ])

        let generator = builder.buildGenerator(from: values)

        #expect(generator?.isRunning == true)
        #expect(generator?.power == 2500)
    }
}
