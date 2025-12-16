// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - SensorKeys

/// Type-safe sensor key namespaces.
///
/// Organizes all sensor keys by domain (Battery, Grid, PV, etc.) with compile-time
/// type checking and autocomplete support. Alternative keys handle different naming
/// conventions across ha-solarman profiles.
///
/// ## Usage
///
/// ```swift
/// let values: SensorValues = ...
/// let soc = values[SensorKeys.Battery.soc]  // Checks "battery_soc", then "battery"
/// ```
///
/// ## Structure
///
/// Each domain has its own namespace:
/// - `SensorKeys.Battery` - Battery measurements
/// - `SensorKeys.Grid` - Grid connection
/// - `SensorKeys.PV` - Solar production
/// - `SensorKeys.Load` - Consumption
/// - `SensorKeys.UPS` - Emergency power
/// - `SensorKeys.Generator` - Generator
/// - `SensorKeys.BMS` - Battery management
/// - `SensorKeys.TimeOfUse` - TOU schedules
/// - `SensorKeys.Inverter` - Device info
public enum SensorKeys {}

// MARK: - Phase Extensions for Key Construction

extension Phase {
    /// CT number for external meter (1, 2, 3).
    var ctNumber: Int {
        switch self {
        case .l1: 1
        case .l2: 2
        case .l3: 3
        }
    }

    /// Growatt-style suffix (r, s, t).
    var growattSuffix: String {
        switch self {
        case .l1: "r"
        case .l2: "s"
        case .l3: "t"
        }
    }
}
