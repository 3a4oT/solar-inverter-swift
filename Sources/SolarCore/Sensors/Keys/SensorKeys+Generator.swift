// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

extension SensorKeys {
    /// Generator sensor keys.
    public enum Generator {
        /// Total generator power in Watts.
        public static let power = SensorKey(
            "generator_power",
            alternatives: ["total_generator_power"],
        )

        /// Daily generator production in kWh.
        /// Note: "generator_energy___today" has triple underscore in some profiles.
        public static let dailyProduction = SensorKey(
            "daily_generator_production",
            alternatives: ["generator_energy___today", "generator_daily"],
        )

        /// Total generator production in kWh (lifetime).
        public static let totalProduction = SensorKey(
            "total_generator_production",
            alternatives: ["generator_energy", "generator_total"],
        )

        /// Phase voltage for three-phase generator.
        public static func phaseVoltage(_ phase: Phase) -> SensorKey {
            SensorKey("generator_\(phase.rawValue)_voltage")
        }

        /// Phase power for three-phase generator.
        public static func phasePower(_ phase: Phase) -> SensorKey {
            SensorKey("generator_\(phase.rawValue)_power")
        }
    }
}
