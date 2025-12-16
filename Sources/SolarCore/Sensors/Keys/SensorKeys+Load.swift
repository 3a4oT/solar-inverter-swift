// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

extension SensorKeys {
    /// Load (consumption) sensor keys.
    public enum Load {
        /// Total load power in Watts.
        public static let power = SensorKey("load_power", alternatives: ["total_load_power"])

        /// Load output frequency in Hz.
        public static let frequency = SensorKey("load_frequency")

        /// Daily load consumption in kWh.
        public static let dailyConsumption = SensorKey(
            "daily_load_consumption",
            alternatives: ["today_load_consumption", "daily_load"],
        )

        /// Total load consumption in kWh (lifetime).
        public static let totalConsumption = SensorKey(
            "total_load_consumption",
            alternatives: ["total_load"],
        )

        /// Phase power for three-phase systems.
        public static func phasePower(_ phase: Phase) -> SensorKey {
            SensorKey("load_\(phase.rawValue)_power")
        }

        /// Phase voltage for three-phase systems.
        public static func phaseVoltage(_ phase: Phase) -> SensorKey {
            SensorKey("load_\(phase.rawValue)_voltage")
        }

        /// Phase current for three-phase systems.
        /// Note: Some profiles (deye_p3) only have "output_lX_current" without "load_lX_current".
        public static func phaseCurrent(_ phase: Phase) -> SensorKey {
            SensorKey(
                "load_\(phase.rawValue)_current",
                alternatives: ["output_\(phase.rawValue)_current"],
            )
        }
    }
}
