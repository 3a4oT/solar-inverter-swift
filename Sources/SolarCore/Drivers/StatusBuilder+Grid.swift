// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

extension StatusBuilder {
    // MARK: Internal

    /// Build `GridStatus` from extracted values.
    func buildGrid(from values: SensorValues) -> GridStatus? {
        guard !values.isEmpty else {
            return nil
        }

        typealias K = SensorKeys.Grid

        guard let power = values.int(K.power) else {
            return nil
        }

        // Build phase(s) - single phase for now
        let phases = buildGridPhases(from: values, totalPower: power)

        // Build external CT meter if available
        let externalCT = buildExternalCT(from: values)

        return GridStatus(
            frequency: values[K.frequency],
            power: power,
            phases: phases,
            powerFactor: values[K.powerFactor],
            dailyImport: values[K.dailyImport],
            dailyExport: values[K.dailyExport],
            totalImport: values[K.totalImport],
            totalExport: values[K.totalExport],
            externalCT: externalCT,
        )
    }

    // MARK: Private

    private func buildGridPhases(
        from values: SensorValues,
        totalPower: Int,
    ) -> [PhaseStatus] {
        typealias K = SensorKeys.Grid
        var phases: [PhaseStatus] = []

        // Three-phase: L1, L2, L3
        for phase in Phase.allCases {
            if let voltage = values[K.phaseVoltage(phase)] {
                let current = values[K.phaseCurrent(phase)] ?? 0
                let power = values.int(K.phasePower(phase)) ?? 0
                phases.append(
                    PhaseStatus(
                        phase: phase,
                        voltage: voltage,
                        current: current,
                        power: power,
                    ))
            }
        }

        // Single-phase fallback
        if phases.isEmpty, let voltage = values[K.voltage] {
            let current = values[K.current] ?? 0
            phases.append(
                PhaseStatus(
                    phase: .l1,
                    voltage: voltage,
                    current: current,
                    power: totalPower,
                ))
        }

        return phases
    }

    /// Build external CT meter measurements.
    private func buildExternalCT(from values: SensorValues) -> ExternalCTMeter? {
        typealias K = SensorKeys.Grid

        // Check if external CT data is available
        let hasExternalData =
            values.contains(K.externalPower)
                || values.contains(K.externalCTPower(.l1))
                || values.contains(K.externalCTPower(.l2))
                || values.contains(K.externalCTPower(.l3))

        guard hasExternalData else {
            return nil
        }

        // Build per-phase measurements
        var ctPhases: [CTPhase] = []

        for phase in Phase.allCases {
            if let power = values.int(K.externalCTPower(phase)) {
                ctPhases.append(
                    CTPhase(
                        phase: phase,
                        power: power,
                        current: values[K.externalCTCurrent(phase)],
                    ))
            }
        }

        // Total external power
        let totalPower =
            values.int(K.externalPower)
                ?? ctPhases.reduce(0) { $0 + $1.power }

        return ExternalCTMeter(
            power: totalPower,
            phases: ctPhases,
        )
    }
}
