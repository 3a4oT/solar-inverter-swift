// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

extension StatusBuilder {
    // MARK: Internal

    /// Build `GeneratorStatus` from extracted values.
    func buildGenerator(from values: SensorValues) -> GeneratorStatus? {
        guard !values.isEmpty else {
            return nil
        }

        typealias K = SensorKeys.Generator

        guard let power = values[K.power] else {
            return nil
        }

        // Build phase(s) for three-phase systems
        let phases = buildGeneratorPhases(from: values)

        // Generator power is always positive (abs)
        let absPower = Int(abs(power))

        // isRunning: determined by power > 0 (no explicit sensor in most profiles)
        let isRunning = absPower > 0

        return GeneratorStatus(
            power: absPower,
            phases: phases,
            dailyProduction: values[K.dailyProduction],
            totalProduction: values[K.totalProduction],
            isRunning: isRunning,
        )
    }

    // MARK: Private

    private func buildGeneratorPhases(from values: SensorValues) -> [GeneratorPhase] {
        typealias K = SensorKeys.Generator
        var phases: [GeneratorPhase] = []

        for phase in Phase.allCases {
            if let power = values[K.phasePower(phase)] {
                let voltage = values[K.phaseVoltage(phase)] ?? 0
                phases.append(
                    GeneratorPhase(
                        phase: phase,
                        voltage: voltage,
                        power: Int(abs(power)),
                    ))
            }
        }

        return phases
    }
}
