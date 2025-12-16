// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

extension SensorKeys {
    /// Battery sensor keys.
    public enum Battery {
        /// State of charge (0-100%).
        /// Alternatives: some profiles use just "battery" for SOC.
        public static let soc = SensorKey("battery_soc", alternatives: ["battery"])

        /// Battery voltage in Volts.
        public static let voltage = SensorKey("battery_voltage")

        /// Battery power in Watts (positive = discharge, negative = charge).
        public static let power = SensorKey("battery_power")

        /// Battery current in Amps.
        public static let current = SensorKey("battery_current")

        /// Battery temperature in Celsius.
        public static let temperature = SensorKey("battery_temperature")

        /// State of health (0-100%).
        /// Indicates battery degradation over time.
        public static let soh = SensorKey("battery_soh")

        /// Daily charge energy in kWh.
        public static let dailyCharge = SensorKey(
            "battery_daily_charge",
            alternatives: ["today_battery_charge", "daily_battery_charge"],
        )

        /// Daily discharge energy in kWh.
        public static let dailyDischarge = SensorKey(
            "battery_daily_discharge",
            alternatives: ["today_battery_discharge", "daily_battery_discharge"],
        )

        /// Total charge energy in kWh (lifetime).
        public static let totalCharge = SensorKey(
            "battery_total_charge",
            alternatives: ["total_battery_charge"],
        )

        /// Total discharge energy in kWh (lifetime).
        public static let totalDischarge = SensorKey(
            "battery_total_discharge",
            alternatives: ["total_battery_discharge"],
        )
    }
}
