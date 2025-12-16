// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

extension SensorKeys {
    /// Time-of-Use schedule sensor keys.
    public enum TimeOfUse {
        /// Weekly schedule bitmask.
        public static let weeklySchedule = SensorKey("time_of_use")

        /// Program slot time (HHMM → minutes from midnight).
        public static func slotTime(_ slot: Int) -> SensorKey {
            SensorKey("program_\(slot)_time")
        }

        /// Program slot target SOC.
        public static func slotSOC(_ slot: Int) -> SensorKey {
            SensorKey("program_\(slot)_soc")
        }

        /// Program slot charge power limit.
        public static func slotPower(_ slot: Int) -> SensorKey {
            SensorKey("program_\(slot)_power")
        }

        /// Program slot charge voltage threshold.
        public static func slotVoltage(_ slot: Int) -> SensorKey {
            SensorKey("program_\(slot)_voltage")
        }

        /// Program slot charging mode (0 = disabled, 1 = enabled).
        public static func slotCharging(_ slot: Int) -> SensorKey {
            SensorKey("program_\(slot)_charging")
        }
    }
}
