// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

extension StatusBuilder {
    // MARK: Internal

    /// Build `PVStatus` from extracted values.
    func buildPV(from values: SensorValues) -> PVStatus? {
        guard !values.isEmpty else {
            return nil
        }

        typealias K = SensorKeys.PV

        // Build individual strings (PV1-PV4)
        let strings = buildPVStrings(from: values)

        // Total power: dedicated sensor or sum of strings
        let totalPower =
            values.int(K.totalPower)
                ?? strings.reduce(0) { $0 + $1.power }

        return PVStatus(
            power: totalPower,
            strings: strings,
            dailyProduction: values[K.dailyProduction],
            totalProduction: values[K.totalProduction],
        )
    }

    // MARK: Private

    private func buildPVStrings(from values: SensorValues) -> [PVString] {
        typealias K = SensorKeys.PV

        return (1...4).compactMap { i -> PVString? in
            guard let power = values.int(K.stringPower(i)) else {
                return nil
            }

            let voltage = values[K.stringVoltage(i)] ?? 0
            let current =
                values[K.stringCurrent(i)]
                    ?? (voltage > 0 ? Double(power) / voltage : 0)

            return PVString(
                id: i,
                voltage: voltage,
                current: current,
                power: power,
            )
        }
    }
}
