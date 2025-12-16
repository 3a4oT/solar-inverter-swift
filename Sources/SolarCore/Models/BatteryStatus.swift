// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

/// Battery subsystem status.
///
/// Power sign convention:
/// - **Positive** = discharging (battery → load)
/// - **Negative** = charging (PV/grid → battery)
///
/// Based on Deye hybrid inverter register map (0xB6-0xBF).
///
/// ## Example
///
/// ```swift
/// let battery = BatteryStatus(
///     soc: 85,
///     voltage: 410.5,
///     current: 12.5,
///     power: 5125
/// )
/// print("SOC: \(battery.soc)%")  // "SOC: 85%"
/// ```
public struct BatteryStatus: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    /// Creates a new battery status.
    ///
    /// - Parameters:
    ///   - soc: State of charge (0-100%).
    ///   - voltage: Battery voltage in Volts.
    ///   - current: Battery current in Amps (positive = discharge).
    ///   - power: Battery power in Watts (positive = discharge).
    ///   - temperature: Battery temperature in Celsius.
    ///   - dailyCharge: Daily charge energy in kWh.
    ///   - dailyDischarge: Daily discharge energy in kWh.
    ///   - totalCharge: Total charge energy in kWh.
    ///   - totalDischarge: Total discharge energy in kWh.
    public init(
        soc: Int,
        voltage: Double,
        current: Double,
        power: Int,
        temperature: Double? = nil,
        soh: Int? = nil,
        dailyCharge: Double? = nil,
        dailyDischarge: Double? = nil,
        totalCharge: Double? = nil,
        totalDischarge: Double? = nil,
    ) {
        self.soc = soc
        self.voltage = voltage
        self.current = current
        self.power = power
        self.temperature = temperature
        self.soh = soh
        self.dailyCharge = dailyCharge
        self.dailyDischarge = dailyDischarge
        self.totalCharge = totalCharge
        self.totalDischarge = totalDischarge
    }

    // MARK: Public

    /// State of charge (0-100%).
    public let soc: Int

    /// Battery voltage in Volts.
    public let voltage: Double

    /// Battery current in Amps.
    ///
    /// Positive = discharging, negative = charging.
    public let current: Double

    /// Battery power in Watts.
    ///
    /// Positive = discharging, negative = charging.
    public let power: Int

    /// Battery temperature in Celsius.
    public let temperature: Double?

    /// State of health (0-100%).
    ///
    /// Indicates battery degradation over time. Calculated from:
    /// - Total charge/discharge cycles
    /// - Capacity retention vs nominal
    ///
    /// 100% = New battery, decreases with age and usage.
    public let soh: Int?

    /// Daily charge energy in kWh.
    public let dailyCharge: Double?

    /// Daily discharge energy in kWh.
    public let dailyDischarge: Double?

    /// Total charge energy in kWh (lifetime).
    public let totalCharge: Double?

    /// Total discharge energy in kWh (lifetime).
    public let totalDischarge: Double?
}
