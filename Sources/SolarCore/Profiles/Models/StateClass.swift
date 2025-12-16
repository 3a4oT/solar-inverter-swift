// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

/// State class from upstream ha-solarman format.
///
/// Defines how values should be accumulated/displayed over time.
public enum StateClass: String, Sendable, Codable, Equatable, CaseIterable {
    /// Instantaneous measurement that can go up or down.
    /// Example: temperature, power, voltage.
    case measurement

    /// Cumulative total that only increases.
    /// Example: total energy produced.
    case totalIncreasing = "total_increasing"

    /// Cumulative total that can be reset.
    /// Example: daily energy.
    case total
}
