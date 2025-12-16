// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - PVStatus

/// Solar panel (PV) production status.
///
/// Supports up to 4 MPPT strings (PV1-PV4).
/// All power values are positive (generation only).
public struct PVStatus: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    /// Creates a new PV status.
    public init(
        power: Int,
        strings: [PVString],
        dailyProduction: Double? = nil,
        totalProduction: Double? = nil,
    ) {
        self.power = power
        self.strings = strings
        self.dailyProduction = dailyProduction
        self.totalProduction = totalProduction
    }

    // MARK: Public

    /// Total PV power in Watts.
    public let power: Int

    /// Individual string (MPPT input) measurements.
    ///
    /// Most hybrid inverters have 2 strings (PV1, PV2).
    /// Some models support up to 4 strings.
    public let strings: [PVString]

    /// Daily production in kWh.
    public let dailyProduction: Double?

    /// Total production in kWh (lifetime).
    public let totalProduction: Double?
}

// MARK: - PVString

/// Single PV string (MPPT input) measurements.
public struct PVString: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    /// Creates a new PV string measurement.
    public init(
        id: Int,
        voltage: Double,
        current: Double,
        power: Int,
    ) {
        self.id = id
        self.voltage = voltage
        self.current = current
        self.power = power
    }

    // MARK: Public

    /// String identifier (1-4).
    public let id: Int

    /// Voltage in Volts.
    public let voltage: Double

    /// Current in Amps.
    public let current: Double

    /// Power in Watts.
    public let power: Int
}
