// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - UPSStatus

/// UPS (Uninterruptible Power Supply) output status.
///
/// Represents the backup/UPS output of hybrid inverters.
/// This is the power delivered to critical loads during grid outage.
public struct UPSStatus: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    /// Creates a new UPS status.
    public init(
        power: Int,
        phases: [UPSPhase],
        dailyConsumption: Double? = nil,
        totalConsumption: Double? = nil,
        mode: UPSMode? = nil,
    ) {
        self.power = power
        self.phases = phases
        self.dailyConsumption = dailyConsumption
        self.totalConsumption = totalConsumption
        self.mode = mode
    }

    // MARK: Public

    /// Total UPS load power in Watts.
    public let power: Int

    /// Phase-specific UPS output measurements.
    public let phases: [UPSPhase]

    /// Daily UPS energy consumption in kWh.
    public let dailyConsumption: Double?

    /// Total UPS energy consumption in kWh (lifetime).
    public let totalConsumption: Double?

    /// UPS operating mode.
    public let mode: UPSMode?
}

// MARK: - UPSPhase

/// Single UPS output phase measurement.
public struct UPSPhase: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    /// Creates a new UPS phase measurement.
    public init(phase: Phase, voltage: Double, power: Int) {
        self.phase = phase
        self.voltage = voltage
        self.power = power
    }

    // MARK: Public

    /// Phase identifier (L1, L2, L3).
    public let phase: Phase

    /// Output voltage in Volts.
    public let voltage: Double

    /// Output power in Watts.
    public let power: Int
}

// MARK: - UPSMode

/// UPS operating mode.
public enum UPSMode: String, Sendable, Codable {
    /// Grid power available, UPS in standby.
    case standby

    /// Grid failure, running on battery.
    case battery

    /// Grid failure, running on generator.
    case generator

    /// Bypass mode (direct grid to load).
    case bypass

    /// Mode could not be determined.
    case unknown
}
