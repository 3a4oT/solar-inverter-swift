// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

extension SensorKeys {
    /// Grid sensor keys.
    public enum Grid {
        /// Total grid power in Watts (positive = import, negative = export).
        public static let power = SensorKey("grid_power", alternatives: ["total_grid_power"])

        /// Grid frequency in Hz.
        public static let frequency = SensorKey("grid_frequency")

        /// Single-phase voltage (fallback when no L1/L2/L3).
        public static let voltage = SensorKey("grid_voltage")

        /// Single-phase current (fallback when no L1/L2/L3).
        public static let current = SensorKey("grid_current")

        /// Daily energy imported from grid in kWh.
        public static let dailyImport = SensorKey(
            "daily_grid_import",
            alternatives: ["today_energy_import", "daily_energy_bought"],
        )

        /// Daily energy exported to grid in kWh.
        public static let dailyExport = SensorKey(
            "daily_grid_export",
            alternatives: ["today_energy_export", "daily_energy_sold"],
        )

        /// Total energy imported from grid in kWh (lifetime).
        public static let totalImport = SensorKey(
            "total_grid_import",
            alternatives: ["total_energy_import", "total_energy_bought"],
        )

        /// Total energy exported to grid in kWh (lifetime).
        public static let totalExport = SensorKey(
            "total_grid_export",
            alternatives: ["total_energy_export", "total_energy_sold"],
        )

        /// Grid power factor as percentage (0-100%).
        public static let powerFactor = SensorKey("grid_power_factor")

        // MARK: External CT / Smart Meter

        /// External Smart Meter total power.
        public static let externalPower = SensorKey("external_power")

        /// Phase voltage for three-phase systems.
        public static func phaseVoltage(_ phase: Phase) -> SensorKey {
            SensorKey("grid_\(phase.rawValue)_voltage")
        }

        /// Phase current for three-phase systems.
        public static func phaseCurrent(_ phase: Phase) -> SensorKey {
            SensorKey("grid_\(phase.rawValue)_current")
        }

        /// Phase power for three-phase systems.
        public static func phasePower(_ phase: Phase) -> SensorKey {
            SensorKey("grid_\(phase.rawValue)_power")
        }

        /// External CT phase power.
        public static func externalCTPower(_ phase: Phase) -> SensorKey {
            SensorKey("external_ct\(phase.ctNumber)_power")
        }

        /// External CT phase current.
        public static func externalCTCurrent(_ phase: Phase) -> SensorKey {
            SensorKey("external_ct\(phase.ctNumber)_current")
        }
    }
}
