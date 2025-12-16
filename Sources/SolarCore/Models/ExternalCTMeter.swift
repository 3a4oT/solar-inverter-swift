// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - ExternalCTMeter

/// External CT (Current Transformer) or Smart Meter measurements.
///
/// Represents data from an external meter installed at the grid connection point.
/// This provides more accurate grid measurements than the inverter's internal sensors,
/// especially when some loads bypass the inverter (e.g., direct grid connections).
///
/// ## Difference from GridStatus.phases
///
/// - **GridStatus.phases**: Measurements from inverter's internal CT sensors.
///   Only sees power flowing through the inverter.
/// - **ExternalCTMeter**: Measurements from external Smart Meter at grid entry point.
///   Sees total household consumption including loads that bypass the inverter.
///
/// ## Power Sign Convention
///
/// - **Positive**: Importing from grid (consuming)
/// - **Negative**: Exporting to grid (selling)
public struct ExternalCTMeter: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    /// Creates external CT meter measurements.
    public init(
        power: Int,
        phases: [CTPhase],
    ) {
        self.power = power
        self.phases = phases
    }

    // MARK: Public

    /// Total external meter power in Watts.
    public let power: Int

    /// Per-phase CT measurements.
    public let phases: [CTPhase]
}

// MARK: - CTPhase

/// Single phase CT meter measurement.
///
/// ## Current vs Power Discrepancy
///
/// The current value may not match `power / voltage` due to:
/// - **Power factor**: Reactive loads (motors, capacitors) cause phase shift
/// - **Measurement timing**: Current and power sampled at different moments
/// - **Averaging**: Some meters report RMS vs instantaneous values
public struct CTPhase: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    /// Creates a CT phase measurement.
    public init(
        phase: Phase,
        power: Int,
        current: Double? = nil,
    ) {
        self.phase = phase
        self.power = power
        self.current = current
    }

    // MARK: Public

    /// Phase identifier (L1, L2, L3).
    public let phase: Phase

    /// Active power in Watts (positive = import, negative = export).
    public let power: Int

    /// RMS current in Amps (optional).
    ///
    /// Note: May not equal `power / voltage` due to power factor.
    public let current: Double?
}
