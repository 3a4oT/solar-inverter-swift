// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - LoadStatus

/// Load (consumption) status.
///
/// All power values are positive (consumption only).
public struct LoadStatus: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    /// Creates a new load status.
    public init(
        power: Int,
        phases: [PhaseLoad]? = nil,
        frequency: Double? = nil,
        dailyConsumption: Double? = nil,
        totalConsumption: Double? = nil,
    ) {
        self.power = power
        self.phases = phases
        self.frequency = frequency
        self.dailyConsumption = dailyConsumption
        self.totalConsumption = totalConsumption
    }

    // MARK: Public

    /// Total load power in Watts.
    public let power: Int

    /// Phase-specific load power (for three-phase systems).
    public let phases: [PhaseLoad]?

    /// Load output frequency in Hz.
    public let frequency: Double?

    /// Daily consumption in kWh.
    public let dailyConsumption: Double?

    /// Total consumption in kWh (lifetime).
    public let totalConsumption: Double?
}

// MARK: - PhaseLoad

/// Single phase load measurement.
public struct PhaseLoad: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    /// Creates a new phase load measurement.
    public init(
        phase: Phase,
        power: Int,
        voltage: Double? = nil,
        current: Double? = nil,
    ) {
        self.phase = phase
        self.power = power
        self.voltage = voltage
        self.current = current
    }

    // MARK: Public

    /// Phase identifier (L1, L2, L3).
    public let phase: Phase

    /// Power in Watts.
    public let power: Int

    /// Output voltage in Volts (optional).
    public let voltage: Double?

    /// Output current in Amps (optional).
    public let current: Double?
}
