// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

extension SensorKeys {
    /// UPS (uninterruptible power supply) / EPS sensor keys.
    public enum UPS {
        /// Total UPS power in Watts.
        /// Supports multiple profile naming conventions.
        public static let power = SensorKey(
            "load_ups_power",
            alternatives: ["ups_power", "activepower_load_total_eps"],
        )

        /// Daily UPS consumption in kWh.
        public static let dailyConsumption = SensorKey(
            "daily_ups_consumption",
            alternatives: ["ups_daily"],
        )

        /// Total UPS consumption in kWh (lifetime).
        public static let totalConsumption = SensorKey(
            "total_ups_consumption",
            alternatives: ["ups_total"],
        )

        /// Phase voltage for three-phase UPS.
        public static func phaseVoltage(_ phase: Phase) -> SensorKey {
            SensorKey(
                "load_ups_\(phase.rawValue)_voltage",
                alternatives: [
                    "output_\(phase.rawValue)_voltage",
                    "eps_\(phase.rawValue)_voltage",
                    "voltage_load_\(phase.growattSuffix)_eps",
                ],
            )
        }

        /// Phase power for three-phase UPS.
        public static func phasePower(_ phase: Phase) -> SensorKey {
            SensorKey(
                "load_ups_\(phase.rawValue)_power",
                alternatives: [
                    "eps_\(phase.rawValue)_power",
                    "activepower_load_\(phase.growattSuffix)_eps",
                ],
            )
        }
    }
}
