// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

extension StatusBuilder {
    // MARK: Internal

    /// Build `LoadStatus` from extracted values.
    func buildLoad(from values: SensorValues) -> LoadStatus? {
        guard !values.isEmpty else {
            return nil
        }

        typealias K = SensorKeys.Load

        guard let power = values.int(K.power) else {
            return nil
        }

        // Build phase(s) for three-phase systems
        let phases = buildLoadPhases(from: values)

        return LoadStatus(
            power: power,
            phases: phases.isEmpty ? nil : phases,
            frequency: values[K.frequency],
            dailyConsumption: values[K.dailyConsumption],
            totalConsumption: values[K.totalConsumption],
        )
    }

    // MARK: Private

    /// Build load phases with power, voltage, and current.
    private func buildLoadPhases(from values: SensorValues) -> [PhaseLoad] {
        typealias K = SensorKeys.Load
        var phases: [PhaseLoad] = []

        for phase in Phase.allCases {
            if let power = values.int(K.phasePower(phase)) {
                phases.append(
                    PhaseLoad(
                        phase: phase,
                        power: power,
                        voltage: values[K.phaseVoltage(phase)],
                        current: values[K.phaseCurrent(phase)],
                    ))
            }
        }

        return phases
    }
}
