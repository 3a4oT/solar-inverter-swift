// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - GridStatus

/// Grid connection status.
///
/// Contains measurements from inverter's internal sensors and optionally
/// from an external Smart Meter (see `externalCT`).
///
/// ## Power Sign Convention
///
/// - **Positive** = importing from grid (consuming)
/// - **Negative** = exporting to grid (selling)
///
/// ## Internal vs External Measurements
///
/// - **phases**: From inverter's internal CT sensors. Only measures power
///   flowing through the inverter.
/// - **externalCT**: From external Smart Meter at grid entry point. Measures
///   total household consumption including loads that bypass the inverter.
///
/// When a Smart Meter is installed, `externalCT` provides more accurate
/// grid measurements, especially if some loads connect directly to the grid.
///
/// Supports single-phase (L1 only) and three-phase (L1, L2, L3) systems.
public struct GridStatus: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    /// Creates a new grid status.
    public init(
        frequency: Double? = nil,
        power: Int,
        phases: [PhaseStatus],
        powerFactor: Double? = nil,
        dailyImport: Double? = nil,
        dailyExport: Double? = nil,
        totalImport: Double? = nil,
        totalExport: Double? = nil,
        externalCT: ExternalCTMeter? = nil,
    ) {
        self.frequency = frequency
        self.power = power
        self.phases = phases
        self.powerFactor = powerFactor
        self.dailyImport = dailyImport
        self.dailyExport = dailyExport
        self.totalImport = totalImport
        self.totalExport = totalExport
        self.externalCT = externalCT
    }

    // MARK: Public

    /// Grid frequency in Hz.
    public let frequency: Double?

    /// Total grid power in Watts.
    ///
    /// Positive = importing, negative = exporting.
    public let power: Int

    /// Phase-specific measurements.
    ///
    /// Single-phase systems have one element (L1).
    /// Three-phase systems have three elements (L1, L2, L3).
    public let phases: [PhaseStatus]

    /// Power factor as percentage (0-100%).
    ///
    /// Ratio of real power to apparent power.
    /// Higher values indicate more efficient power usage.
    public let powerFactor: Double?

    /// Daily energy imported from grid in kWh.
    public let dailyImport: Double?

    /// Daily energy exported to grid in kWh.
    public let dailyExport: Double?

    /// Total energy imported from grid in kWh (lifetime).
    public let totalImport: Double?

    /// Total energy exported to grid in kWh (lifetime).
    public let totalExport: Double?

    /// External Smart Meter / CT measurements (optional).
    ///
    /// Present when an external meter is installed at the grid connection point.
    /// Provides more accurate measurements than internal sensors, especially
    /// for loads that bypass the inverter.
    public let externalCT: ExternalCTMeter?
}

// MARK: - PhaseStatus

/// Single phase electrical measurements.
public struct PhaseStatus: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    /// Creates a new phase status.
    public init(
        phase: Phase,
        voltage: Double,
        current: Double,
        power: Int? = nil,
    ) {
        self.phase = phase
        self.voltage = voltage
        self.current = current
        self.power = power
    }

    // MARK: Public

    /// Phase identifier (L1, L2, L3).
    public let phase: Phase

    /// Voltage in Volts.
    public let voltage: Double

    /// Current in Amps.
    public let current: Double

    /// Power in Watts.
    public let power: Int?
}
