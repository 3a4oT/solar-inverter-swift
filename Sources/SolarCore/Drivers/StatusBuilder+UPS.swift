// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

extension StatusBuilder {
    // MARK: Internal

    /// Build `UPSStatus` from extracted values.
    func buildUPS(from values: SensorValues) -> UPSStatus? {
        guard !values.isEmpty else {
            return nil
        }

        typealias K = SensorKeys.UPS

        guard let power = values.int(K.power) else {
            return nil
        }

        // Build phase(s) for three-phase systems
        let phases = buildUPSPhases(from: values)

        return UPSStatus(
            power: power,
            phases: phases,
            dailyConsumption: values[K.dailyConsumption],
            totalConsumption: values[K.totalConsumption],
        )
    }

    /// Build `UPSStatus` with mode derived from Device State.
    ///
    /// This overload accepts device state label to determine UPS operating mode.
    /// Device State values like "Emergency power supply" indicate EPS/battery mode.
    func buildUPS(from values: SensorValues, deviceStateLabel: String?) -> UPSStatus? {
        guard !values.isEmpty else {
            return nil
        }

        typealias K = SensorKeys.UPS

        guard let power = values.int(K.power) else {
            return nil
        }

        let phases = buildUPSPhases(from: values)
        let mode = mapDeviceStateToUPSMode(deviceStateLabel)

        return UPSStatus(
            power: power,
            phases: phases,
            dailyConsumption: values[K.dailyConsumption],
            totalConsumption: values[K.totalConsumption],
            mode: mode,
        )
    }

    /// Map Device State label to UPSMode.
    ///
    /// Upstream profiles use Device State lookup values:
    /// - "Emergency power supply" → battery mode (EPS active)
    /// - "On-grid", "Normal", "Running" → standby (grid available)
    /// - "Off-grid" → battery mode
    func mapDeviceStateToUPSMode(_ label: String?) -> UPSMode? {
        guard let label else {
            return nil
        }

        switch label.lowercased() {
        case "emergency power supply",
             "eps",
             "off-grid",
             "discharging": // Battery discharging to load
            return .battery
        case "on-grid",
             "normal",
             "running",
             "standby",
             "stand-by",
             "waiting",
             "charging",
             "charging check":
            return .standby
        case "bypass":
            return .bypass
        default:
            return nil
        }
    }

    // MARK: Private

    private func buildUPSPhases(from values: SensorValues) -> [UPSPhase] {
        typealias K = SensorKeys.UPS
        var phases: [UPSPhase] = []

        for phase in Phase.allCases {
            if let power = values.int(K.phasePower(phase)) {
                let voltage = values[K.phaseVoltage(phase)] ?? 0
                phases.append(
                    UPSPhase(
                        phase: phase,
                        voltage: voltage,
                        power: power,
                    ))
            }
        }

        return phases
    }
}
