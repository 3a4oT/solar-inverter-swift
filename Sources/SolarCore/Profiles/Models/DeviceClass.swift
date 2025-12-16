// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

/// Device class from upstream ha-solarman format.
///
/// Maps to Home Assistant device classes for proper UI presentation.
public enum DeviceClass: String, Sendable, Codable, Equatable, CaseIterable {
    // MARK: - Energy & Power

    /// Power measurement (W, kW).
    case power

    /// Energy measurement (Wh, kWh).
    case energy

    /// Voltage measurement (V).
    case voltage

    /// Current measurement (A).
    case current

    /// Frequency measurement (Hz).
    case frequency

    /// Power factor (ratio).
    case powerFactor = "power_factor"

    /// Apparent power (VA).
    case apparentPower = "apparent_power"

    /// Reactive power (var).
    case reactivePower = "reactive_power"

    /// Total increasing counter (cumulative energy).
    case totalIncreasing = "total_increasing"

    /// Total counter.
    case total

    // MARK: - Battery

    /// Battery charge level (%).
    case battery

    /// Energy storage device.
    case energyStorage = "energy_storage"

    // MARK: - Environmental

    /// Temperature (°C, °F).
    case temperature

    /// Humidity (%).
    case humidity

    /// Resistance (Ohm).
    case resistance

    // MARK: - Status & Control

    /// Enumeration/status value.
    case `enum`

    /// Duration/time span.
    case duration

    /// Timestamp.
    case timestamp

    /// Generic numeric value.
    case measurement

    /// Problem/fault indicator.
    case problem

    /// Running state.
    case running

    /// Restart control.
    case restart

    /// No specific class.
    case none
}
