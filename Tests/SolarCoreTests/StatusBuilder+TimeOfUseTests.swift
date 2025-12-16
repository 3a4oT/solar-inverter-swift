// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

@testable import SolarCore
import Testing

// MARK: - TimeOfUse StatusBuilder Tests

@Suite("StatusBuilder+TimeOfUse")
struct StatusBuilderTimeOfUseTests {
    let builder = StatusBuilder()

    @Test("Builds TOU schedule from values")
    func buildTOUValid() {
        // RegisterConverter converts HHMM to minutes, so values are already in minutes
        let values = SensorValues([
            "program_1_time": 480, // 08:00 = 8*60 = 480 minutes
            "program_1_power": 3000,
            "program_1_voltage": 54.0,
            "program_1_soc": 100,
            "program_1_charging": 1, // Grid charge enabled
        ])

        let tou = builder.buildTimeOfUse(from: values)

        #expect(tou?.slots.count == 1)
        let slot = tou?.slots.first
        #expect(slot?.id == 1)
        #expect(slot?.startTime == 480) // 480 minutes
        #expect(slot?.isEnabled == true)
        #expect(slot?.targetSOC == 100)
        #expect(slot?.chargePower == 3000)
        #expect(slot?.chargeVoltage == 54.0)
        #expect(slot?.mode == .gridCharge)
    }

    @Test("Builds multiple TOU slots")
    func buildTOUMultipleSlots() {
        // Values already in minutes from midnight
        let values = SensorValues([
            "program_1_time": 360, // 06:00 = 6*60 = 360 minutes
            "program_1_soc": 100,
            "program_1_charging": 1,
            "program_2_time": 720, // 12:00 = 12*60 = 720 minutes
            "program_2_soc": 80,
            "program_2_charging": 0,
            "program_3_time": 1080, // 18:00 = 18*60 = 1080 minutes
            "program_3_soc": 50,
            "program_3_charging": 1,
        ])

        let tou = builder.buildTimeOfUse(from: values)

        #expect(tou?.slots.count == 3)
        #expect(tou?.slots[0].startTime == 360)
        #expect(tou?.slots[1].startTime == 720)
        #expect(tou?.slots[2].startTime == 1080)
    }

    @Test("Parses weekly schedule bitmask")
    func buildTOUWeeklySchedule() {
        let values = SensorValues([
            "program_1_time": 480, // 08:00 = 480 minutes
            "time_of_use": 0x3F, // Monday-Friday (bits 0-4) + Saturday (bit 5) = Weekdays
        ])

        let tou = builder.buildTimeOfUse(from: values)

        #expect(tou?.sellingSchedule != nil)
        #expect(tou?.sellingSchedule?.monday == true)
        #expect(tou?.sellingSchedule?.tuesday == true)
        #expect(tou?.sellingSchedule?.wednesday == true)
        #expect(tou?.sellingSchedule?.thursday == true)
        #expect(tou?.sellingSchedule?.friday == true)
        #expect(tou?.sellingSchedule?.saturday == true)
        #expect(tou?.sellingSchedule?.sunday == false)
    }

    @Test("Slot mode selfConsumption when charging disabled")
    func buildTOUModeSelfConsumption() {
        let values = SensorValues([
            "program_1_time": 600, // 10:00 = 600 minutes
            "program_1_charging": 0, // Disabled
        ])

        let tou = builder.buildTimeOfUse(from: values)

        #expect(tou?.slots.first?.mode == .selfConsumption)
        #expect(tou?.slots.first?.isEnabled == false)
    }

    @Test("Slot enabled by default when no charging sensor")
    func buildTOUDefaultEnabled() {
        let values = SensorValues([
            "program_1_time": 700,
            "program_1_soc": 90,
            // No charging sensor
        ])

        let tou = builder.buildTimeOfUse(from: values)

        #expect(tou?.slots.first?.isEnabled == true)
        #expect(tou?.slots.first?.mode == nil)
    }

    @Test("Returns nil for empty values")
    func buildTOUEmpty() {
        let values = SensorValues([:])

        let tou = builder.buildTimeOfUse(from: values)

        #expect(tou == nil)
    }

    @Test("Returns nil when no time slots configured")
    func buildTOUNoSlots() {
        let values = SensorValues([
            "time_of_use": 0xFF, // Only weekly schedule, no slots
        ])

        let tou = builder.buildTimeOfUse(from: values)

        #expect(tou == nil)
    }

    @Test("Handles edge case times correctly")
    func buildTOUTimeEdgeCases() {
        // Values are already in minutes from midnight (RegisterConverter converts HHMM → minutes)
        let values = SensorValues([
            "program_1_time": 0, // 00:00 = midnight = 0 minutes
            "program_2_time": 1439, // 23:59 = 23*60 + 59 = 1439 minutes
        ])

        let tou = builder.buildTimeOfUse(from: values)

        #expect(tou?.slots.count == 2)
        #expect(tou?.slots[0].startTime == 0) // 0 minutes (midnight)
        #expect(tou?.slots[1].startTime == 1439) // 1439 minutes (23:59)
    }

    @Test("Builds all 6 slots when configured")
    func buildTOUAllSixSlots() {
        // Values already in minutes from midnight
        var raw: [String: Double] = [:]
        for i in 1...6 {
            raw["program_\(i)_time"] = Double(i * 60) // 01:00=60, 02:00=120, etc.
        }
        let values = SensorValues(raw)

        let tou = builder.buildTimeOfUse(from: values)

        #expect(tou?.slots.count == 6)
        for i in 0..<6 {
            #expect(tou?.slots[i].id == i + 1)
            #expect(tou?.slots[i].startTime == (i + 1) * 60)
        }
    }
}
