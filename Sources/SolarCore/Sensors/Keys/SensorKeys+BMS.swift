// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

extension SensorKeys {
    /// BMS (battery management system) sensor keys.
    ///
    /// All keys are constructed with a prefix (e.g., "battery_1", "battery_2", "battery_bms").
    /// This allows support for multiple BMS units in a single system.
    public enum BMS {
        /// SOC for BMS unit.
        /// Some profiles use just the prefix for SOC (e.g., "battery_1" instead of "battery_1_soc").
        public static func soc(prefix: String) -> SensorKey {
            SensorKey("\(prefix)_soc", alternatives: [prefix])
        }

        /// Voltage for BMS unit.
        public static func voltage(prefix: String) -> SensorKey {
            SensorKey("\(prefix)_voltage")
        }

        /// Current for BMS unit.
        public static func current(prefix: String) -> SensorKey {
            SensorKey("\(prefix)_current")
        }

        /// State of health for BMS unit.
        public static func soh(prefix: String) -> SensorKey {
            SensorKey("\(prefix)_soh")
        }

        /// Temperature for BMS unit.
        public static func temperature(prefix: String) -> SensorKey {
            SensorKey("\(prefix)_temperature")
        }

        /// Cycle count for BMS unit.
        public static func cycles(prefix: String) -> SensorKey {
            SensorKey("\(prefix)_cycles")
        }

        /// Charging voltage limit.
        public static func chargingVoltage(prefix: String) -> SensorKey {
            SensorKey("\(prefix)_charging_voltage")
        }

        /// Discharging voltage limit.
        public static func dischargingVoltage(prefix: String) -> SensorKey {
            SensorKey("\(prefix)_discharging_voltage")
        }

        /// Max charging current.
        public static func maxChargingCurrent(prefix: String) -> SensorKey {
            SensorKey("\(prefix)_max_charging_current")
        }

        /// Max discharging current.
        public static func maxDischargingCurrent(prefix: String) -> SensorKey {
            SensorKey("\(prefix)_max_discharging_current")
        }

        /// Charging current limit.
        public static func chargingCurrent(prefix: String) -> SensorKey {
            SensorKey("\(prefix)_charging_current")
        }

        /// Discharging current limit.
        public static func dischargingCurrent(prefix: String) -> SensorKey {
            SensorKey("\(prefix)_discharging_current")
        }

        /// Minimum cell voltage.
        public static func minCellVoltage(prefix: String) -> SensorKey {
            SensorKey("\(prefix)_min_cell_voltage")
        }

        /// Maximum cell voltage.
        public static func maxCellVoltage(prefix: String) -> SensorKey {
            SensorKey("\(prefix)_max_cell_voltage")
        }

        /// Cell count.
        public static func cellCount(prefix: String) -> SensorKey {
            SensorKey("\(prefix)_cell_count")
        }

        /// Minimum cell temperature.
        public static func minCellTemperature(prefix: String) -> SensorKey {
            SensorKey("\(prefix)_min_cell_temperature")
        }

        /// Maximum cell temperature.
        public static func maxCellTemperature(prefix: String) -> SensorKey {
            SensorKey("\(prefix)_max_cell_temperature")
        }
    }
}
