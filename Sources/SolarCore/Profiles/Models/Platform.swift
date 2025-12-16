// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - Platform

/// Sensor platform type from upstream ha-solarman format.
///
/// Defines the Home Assistant entity type and read/write behavior.
public enum Platform: String, Sendable, Codable, Equatable, CaseIterable {
    /// Read-only measurement sensor.
    case sensor

    /// Binary on/off state.
    case binarySensor = "binary_sensor"

    /// Configurable numeric value.
    case number

    /// Enum selection.
    case select

    /// On/off toggle switch.
    case `switch`

    /// Date and time value.
    case datetime

    /// Time-only value.
    case time

    /// Button/action trigger.
    case button
}

// MARK: - Convenience Properties

extension Platform {
    /// Whether this platform supports writing values.
    public var isWritable: Bool {
        switch self {
        case .sensor,
             .binarySensor:
            false
        case .number,
             .select,
             .switch,
             .datetime,
             .time,
             .button:
            true
        }
    }

    /// Whether this is a read-only sensor.
    public var isReadOnly: Bool {
        !isWritable
    }
}
