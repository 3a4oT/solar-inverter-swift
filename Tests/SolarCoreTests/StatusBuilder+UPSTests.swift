// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

@testable import SolarCore
import Testing

// MARK: - UPS StatusBuilder Tests

@Suite("StatusBuilder+UPS")
struct StatusBuilderUPSTests {
    let builder = StatusBuilder()

    @Test("Builds UPS status from values")
    func buildUPSValid() {
        let values = SensorValues([
            "load_ups_power": 500,
            "daily_ups_consumption": 12.5,
            "total_ups_consumption": 3456.7,
        ])

        let ups = builder.buildUPS(from: values)

        #expect(ups?.power == 500)
        #expect(ups?.dailyConsumption == 12.5)
        #expect(ups?.totalConsumption == 3456.7)
    }

    @Test("Returns nil when power missing")
    func buildUPSMissingPower() {
        let values = SensorValues([
            "daily_ups_consumption": 10.0,
        ])

        let ups = builder.buildUPS(from: values)

        #expect(ups == nil)
    }

    @Test("Uses ups_power alternative")
    func buildUPSAlternativePower() {
        let values = SensorValues([
            "ups_power": 750,
        ])

        let ups = builder.buildUPS(from: values)

        #expect(ups?.power == 750)
    }

    @Test("Builds three-phase UPS status")
    func buildUPSThreePhase() {
        let values = SensorValues([
            "load_ups_power": 900,
            "load_ups_l1_voltage": 230.0,
            "load_ups_l1_power": 300,
            "load_ups_l2_voltage": 231.0,
            "load_ups_l2_power": 300,
            "load_ups_l3_voltage": 229.0,
            "load_ups_l3_power": 300,
        ])

        let ups = builder.buildUPS(from: values)

        #expect(ups?.power == 900)
        #expect(ups?.phases.count == 3)
        #expect(ups?.phases[0].phase == .l1)
        #expect(ups?.phases[0].voltage == 230.0)
        #expect(ups?.phases[0].power == 300)
        #expect(ups?.phases[1].phase == .l2)
        #expect(ups?.phases[2].phase == .l3)
    }

    @Test("Single-phase UPS has empty phases array")
    func buildUPSSinglePhase() {
        let values = SensorValues([
            "load_ups_power": 400,
        ])

        let ups = builder.buildUPS(from: values)

        #expect(ups?.power == 400)
        #expect(ups?.phases.isEmpty == true)
    }

    @Test("Returns nil for empty values")
    func buildUPSEmpty() {
        let values = SensorValues([:])

        let ups = builder.buildUPS(from: values)

        #expect(ups == nil)
    }

    @Test("Uses output_l*_voltage alternative (Output group)")
    func buildUPSOutputVoltageAlternative() {
        let values = SensorValues([
            "load_ups_power": 600,
            "output_l1_voltage": 228.5,
            "load_ups_l1_power": 200,
            "output_l2_voltage": 230.0,
            "load_ups_l2_power": 200,
            "output_l3_voltage": 227.5,
            "load_ups_l3_power": 200,
        ])

        let ups = builder.buildUPS(from: values)

        #expect(ups?.phases.count == 3)
        #expect(ups?.phases[0].voltage == 228.5)
        #expect(ups?.phases[1].voltage == 230.0)
        #expect(ups?.phases[2].voltage == 227.5)
    }

    @Test("Uses EPS sensors (Chint profile)")
    func buildUPSFromEPS() {
        let values = SensorValues([
            "activepower_load_total_eps": 1500,
            "eps_l1_voltage": 220.0,
            "eps_l1_power": 500,
            "eps_l2_voltage": 221.0,
            "eps_l2_power": 500,
            "eps_l3_voltage": 219.0,
            "eps_l3_power": 500,
        ])

        let ups = builder.buildUPS(from: values)

        #expect(ups?.power == 1500)
        #expect(ups?.phases.count == 3)
        #expect(ups?.phases[0].voltage == 220.0)
        #expect(ups?.phases[0].power == 500)
    }

    // MARK: - UPS Mode Tests

    @Test("UPS mode standby when Device State is Normal")
    func buildUPSModeStandby() {
        let values = SensorValues([
            "load_ups_power": 500,
        ])

        let ups = builder.buildUPS(from: values, deviceStateLabel: "Normal")

        #expect(ups?.mode == .standby)
    }

    @Test("UPS mode standby when Device State is On-grid")
    func buildUPSModeStandbyOnGrid() {
        let values = SensorValues([
            "load_ups_power": 500,
        ])

        let ups = builder.buildUPS(from: values, deviceStateLabel: "On-grid")

        #expect(ups?.mode == .standby)
    }

    @Test("UPS mode battery when Device State is Emergency power supply")
    func buildUPSModeBatteryEPS() {
        let values = SensorValues([
            "load_ups_power": 800,
        ])

        let ups = builder.buildUPS(from: values, deviceStateLabel: "Emergency power supply")

        #expect(ups?.mode == .battery)
    }

    @Test("UPS mode battery when Device State is Off-grid")
    func buildUPSModeBatteryOffGrid() {
        let values = SensorValues([
            "load_ups_power": 600,
        ])

        let ups = builder.buildUPS(from: values, deviceStateLabel: "Off-grid")

        #expect(ups?.mode == .battery)
    }

    @Test("UPS mode nil when Device State is nil")
    func buildUPSModeNil() {
        let values = SensorValues([
            "load_ups_power": 400,
        ])

        let ups = builder.buildUPS(from: values, deviceStateLabel: nil)

        #expect(ups?.mode == nil)
    }

    @Test("UPS mode nil when Device State is unknown")
    func buildUPSModeUnknown() {
        let values = SensorValues([
            "load_ups_power": 400,
        ])

        let ups = builder.buildUPS(from: values, deviceStateLabel: "SomeUnknownState")

        #expect(ups?.mode == nil)
    }

    @Test("UPS mode bypass")
    func buildUPSModeBypass() {
        let values = SensorValues([
            "load_ups_power": 1000,
        ])

        let ups = builder.buildUPS(from: values, deviceStateLabel: "Bypass")

        #expect(ups?.mode == .bypass)
    }
}
