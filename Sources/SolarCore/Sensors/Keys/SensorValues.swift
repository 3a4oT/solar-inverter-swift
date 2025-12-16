// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - SensorValues

/// Safe accessor for sensor values with alternative key support.
///
/// Wraps raw `[String: Double]` dictionary and provides type-safe access
/// via `SensorKey` with automatic fallback to alternative keys.
///
/// ## Usage
///
/// ```swift
/// let raw: [String: Double] = ["battery_soc": 85.0]
/// let values = SensorValues(raw)
///
/// // Type-safe access with autocomplete
/// let soc = values[SensorKeys.Battery.soc]  // 85.0
///
/// // Dynamic string access (for BMS prefix patterns)
/// let voltage = values["battery_1_voltage"]
/// ```
public struct SensorValues: Sendable {
    // MARK: Lifecycle

    /// Creates a sensor values wrapper.
    ///
    /// - Parameter raw: The underlying dictionary of sensor values.
    public init(_ raw: [String: Double]) {
        self.raw = raw
    }

    // MARK: Public

    /// Whether the underlying dictionary is empty.
    public var isEmpty: Bool {
        raw.isEmpty
    }

    /// Number of values.
    public var count: Int {
        raw.count
    }

    /// All keys in the underlying dictionary.
    public var keys: Dictionary<String, Double>.Keys {
        raw.keys
    }

    /// Access value by SensorKey (checks primary + alternatives in order).
    ///
    /// - Parameter key: The sensor key to look up.
    /// - Returns: The value if found, nil otherwise.
    public subscript(_ key: SensorKey) -> Double? {
        for k in key.allKeys {
            if let value = raw[k] {
                return value
            }
        }
        return nil
    }

    /// Direct access by string key (for dynamic keys like BMS prefix).
    ///
    /// - Parameter key: The string key to look up.
    /// - Returns: The value if found, nil otherwise.
    public subscript(_ key: String) -> Double? {
        raw[key]
    }

    // MARK: Internal

    /// The underlying raw dictionary.
    let raw: [String: Double]
}

// MARK: - Convenience Methods

extension SensorValues {
    /// Check if a key exists (including alternatives).
    ///
    /// - Parameter key: The sensor key to check.
    /// - Returns: True if any key variant exists.
    public func contains(_ key: SensorKey) -> Bool {
        self[key] != nil
    }

    /// Check if a string key exists.
    ///
    /// - Parameter key: The string key to check.
    /// - Returns: True if key exists.
    public func contains(_ key: String) -> Bool {
        raw[key] != nil
    }

    /// Get value with type conversion to Int.
    ///
    /// - Parameter key: The sensor key to look up.
    /// - Returns: The value as Int if found, nil otherwise.
    public func int(_ key: SensorKey) -> Int? {
        self[key].map { Int($0) }
    }

    /// Get value with type conversion to Int (string key).
    ///
    /// - Parameter key: The string key to look up.
    /// - Returns: The value as Int if found, nil otherwise.
    public func int(_ key: String) -> Int? {
        self[key].map { Int($0) }
    }
}
