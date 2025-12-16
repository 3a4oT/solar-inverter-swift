// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

extension SensorKeys {
    /// Inverter device sensor keys.
    public enum Inverter {
        /// Device RTC (real-time clock) time.
        /// Returns datetime string in "YY/MM/DD HH:MM:SS" format.
        public static let deviceTime = SensorKey(
            "date_&_time",
            alternatives: ["device_rtc", "device_time"],
        )

        /// DC temperature (internal).
        public static let dcTemperature = SensorKey(
            "dc_temperature",
            alternatives: ["inverter_dc_temperature"],
        )

        /// AC temperature (internal).
        public static let acTemperature = SensorKey(
            "ac_temperature",
            alternatives: ["inverter_ac_temperature"],
        )

        /// Device rated power in Watts.
        public static let ratedPower = SensorKey("device_rated_power")

        /// Number of MPPTs.
        public static let mpptCount = SensorKey("device_mppts")

        /// Number of phases.
        public static let phaseCount = SensorKey("device_phases")
    }
}
