// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - GeneratorStatus

/// Generator input status.
///
/// For hybrid inverters with generator port (Gen A/B/C).
/// Supports single-phase and three-phase generators.
public struct GeneratorStatus: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    /// Creates a new generator status.
    public init(
        power: Int,
        phases: [GeneratorPhase],
        dailyProduction: Double? = nil,
        totalProduction: Double? = nil,
        isRunning: Bool? = nil,
    ) {
        self.power = power
        self.phases = phases
        self.dailyProduction = dailyProduction
        self.totalProduction = totalProduction
        self.isRunning = isRunning
    }

    // MARK: Public

    /// Total generator power in Watts.
    public let power: Int

    /// Phase-specific measurements.
    public let phases: [GeneratorPhase]

    /// Daily generator production in kWh.
    public let dailyProduction: Double?

    /// Total generator production in kWh (lifetime).
    public let totalProduction: Double?

    /// Generator running status.
    public let isRunning: Bool?
}

// MARK: - GeneratorPhase

/// Single generator phase measurement.
public struct GeneratorPhase: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    /// Creates a new generator phase measurement.
    public init(phase: Phase, voltage: Double, power: Int) {
        self.phase = phase
        self.voltage = voltage
        self.power = power
    }

    // MARK: Public

    /// Phase identifier (A, B, C mapped to L1, L2, L3).
    public let phase: Phase

    /// Voltage in Volts.
    public let voltage: Double

    /// Power in Watts.
    public let power: Int
}
