// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - SensorKey

/// Type-safe sensor key with alternative names support.
///
/// Eliminates magic strings and provides compile-time checking for sensor lookups.
/// Alternative keys handle different naming conventions across inverter profiles.
///
/// ## Example
///
/// ```swift
/// let key = SensorKey("battery_soc", alternatives: ["battery"])
/// // Looks up "battery_soc" first, then "battery"
/// ```
public struct SensorKey: Sendable, Hashable {
    // MARK: Lifecycle

    /// Creates a sensor key with optional alternatives.
    ///
    /// - Parameters:
    ///   - primary: The primary key name (checked first).
    ///   - alternatives: Alternative key names (checked in order if primary missing).
    public init(_ primary: String, alternatives: [String] = []) {
        self.primary = primary
        self.alternatives = alternatives
    }

    // MARK: Public

    /// The primary key name (checked first).
    public let primary: String

    /// Alternative key names for profile compatibility.
    public let alternatives: [String]

    /// All keys in lookup order: primary followed by alternatives.
    public var allKeys: [String] { [primary] + alternatives }
}

// MARK: ExpressibleByStringLiteral

extension SensorKey: ExpressibleByStringLiteral {
    /// Creates a sensor key from a string literal (no alternatives).
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

// MARK: CustomStringConvertible

extension SensorKey: CustomStringConvertible {
    public var description: String {
        if alternatives.isEmpty {
            return primary
        }
        return "\(primary) (alt: \(alternatives.joined(separator: ", ")))"
    }
}
