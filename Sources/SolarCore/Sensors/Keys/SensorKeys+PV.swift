// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

extension SensorKeys {
    /// PV (photovoltaic) sensor keys.
    public enum PV {
        /// Total PV power in Watts.
        public static let totalPower = SensorKey("total_pv_power", alternatives: ["pv_power"])

        /// Daily PV production in kWh.
        public static let dailyProduction = SensorKey(
            "daily_production",
            alternatives: ["today_production", "daily_pv_production"],
        )

        /// Total PV production in kWh (lifetime).
        public static let totalProduction = SensorKey(
            "total_production",
            alternatives: ["total_pv_production"],
        )

        /// PV string power by ID (1-4).
        public static func stringPower(_ id: Int) -> SensorKey {
            SensorKey("pv\(id)_power")
        }

        /// PV string voltage by ID (1-4).
        public static func stringVoltage(_ id: Int) -> SensorKey {
            SensorKey("pv\(id)_voltage")
        }

        /// PV string current by ID (1-4).
        public static func stringCurrent(_ id: Int) -> SensorKey {
            SensorKey("pv\(id)_current")
        }
    }
}
