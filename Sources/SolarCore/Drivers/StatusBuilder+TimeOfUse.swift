// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

extension StatusBuilder {
    // MARK: Internal

    /// Build `TimeOfUseSchedule` from extracted values.
    ///
    /// Extracts TOU configuration from profile sensors:
    /// - `time_of_use` - weekly schedule bitmask
    /// - `program_N_time` - slot start time (HHMM format)
    /// - `program_N_power` - charge power limit
    /// - `program_N_voltage` - charge voltage threshold
    /// - `program_N_soc` - target SOC percentage
    /// - `program_N_charging` - grid charge enabled (0=disabled, 1=enabled)
    func buildTimeOfUse(from values: SensorValues) -> TimeOfUseSchedule? {
        guard !values.isEmpty else {
            return nil
        }

        typealias K = SensorKeys.TimeOfUse

        // Build time slots (up to 6)
        var slots: [TimeSlot] = []

        for i in 1...6 {
            if let slot = buildTimeSlot(from: values, slotId: i) {
                slots.append(slot)
            }
        }

        // If no slots found, return nil
        guard !slots.isEmpty else {
            return nil
        }

        // Weekly schedule from "Time of Use" bitmask
        let weeklySchedule: WeeklySchedule? =
            values.int(K.weeklySchedule).map { WeeklySchedule(bitmask: $0) }

        return TimeOfUseSchedule(
            slots: slots,
            sellingSchedule: weeklySchedule,
        )
    }

    // MARK: Private

    private func buildTimeSlot(from values: SensorValues, slotId: Int) -> TimeSlot? {
        typealias K = SensorKeys.TimeOfUse

        // Time is required (already converted to minutes from midnight by RegisterConverter)
        guard let startTime = values.int(K.slotTime(slotId)) else {
            return nil
        }

        // End time is the start of next slot (or 23:59 for last slot)
        // For simplicity, we don't have explicit end time in deye profiles
        // Set to 0 to indicate "until next slot"
        let endTime = 0

        // isEnabled: check if charging mode is enabled (1) or disabled (0)
        // If no charging sensor, consider slot enabled if time is set
        let isEnabled: Bool =
            if let chargingValue = values[K.slotCharging(slotId)] {
                chargingValue > 0
            } else {
                true // Default to enabled if time is configured
            }

        // Determine mode based on charging setting
        let mode: TimeSlotMode? =
            if let chargingValue = values[K.slotCharging(slotId)] {
                chargingValue > 0 ? .gridCharge : .selfConsumption
            } else {
                nil
            }

        return TimeSlot(
            id: slotId,
            startTime: startTime,
            endTime: endTime,
            isEnabled: isEnabled,
            targetSOC: values.int(K.slotSOC(slotId)),
            chargePower: values.int(K.slotPower(slotId)),
            chargeVoltage: values[K.slotVoltage(slotId)],
            mode: mode,
        )
    }
}
