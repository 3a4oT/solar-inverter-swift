// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

extension StatusBuilder {
    /// Build `BatteryStatus` from extracted values.
    func buildBattery(from values: SensorValues) -> BatteryStatus? {
        guard !values.isEmpty else {
            return nil
        }

        typealias K = SensorKeys.Battery

        // Required fields
        guard
            let soc = values.int(K.soc),
            let voltage = values[K.voltage],
            let power = values.int(K.power)
        else {
            return nil
        }

        // Current: dedicated sensor or calculated from P/V
        let current = values[K.current] ?? (voltage > 0 ? Double(power) / voltage : 0)

        return BatteryStatus(
            soc: soc,
            voltage: voltage,
            current: current,
            power: power,
            temperature: values[K.temperature],
            soh: values.int(K.soh),
            dailyCharge: values[K.dailyCharge],
            dailyDischarge: values[K.dailyDischarge],
            totalCharge: values[K.totalCharge],
            totalDischarge: values[K.totalDischarge],
        )
    }
}
