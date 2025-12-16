// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - SensorGroup

/// Functional grouping of sensors by subsystem.
///
/// Sensors are organized into logical groups matching the data models
/// in `SolarStatus`. This enables selective reading of only required data.
public enum SensorGroup: String, Sendable, Codable, CaseIterable {
    /// Battery metrics (SOC, voltage, current, power, energy).
    case battery

    /// Grid/AC connection metrics (voltage, current, power, frequency).
    case grid

    /// Solar panel production (per-string and total).
    case pv

    /// Load/consumption metrics.
    case load

    /// Inverter device information (status, temperature, faults).
    case inverter

    /// Generator input metrics.
    case generator

    /// UPS output metrics.
    case ups

    /// Battery Management System detailed data.
    case bms

    /// Time-of-Use schedule configuration.
    case timeOfUse

    /// Writable inverter settings.
    case settings

    /// Alert and fault sensors.
    case alerts

    /// Computed/derived sensors.
    case computed
}

// MARK: - Group Metadata

extension SensorGroup {
    /// Default groups for basic monitoring.
    public static let basic: Set<SensorGroup> = [.battery, .grid, .pv, .load]

    /// All status groups (excludes settings which are writable).
    public static let allStatus: Set<SensorGroup> = [
        .battery, .grid, .pv, .load, .inverter,
        .generator, .ups, .bms, .timeOfUse, .alerts,
    ]

    /// Human-readable display name for this group.
    public var displayName: String {
        switch self {
        case .battery: "Battery"
        case .grid: "Grid"
        case .pv: "Solar"
        case .load: "Load"
        case .inverter: "Inverter"
        case .generator: "Generator"
        case .ups: "UPS"
        case .bms: "BMS"
        case .timeOfUse: "Time of Use"
        case .settings: "Settings"
        case .alerts: "Alerts"
        case .computed: "Computed"
        }
    }
}

// MARK: - Upstream Mapping

extension SensorGroup {
    /// Upstream ha-solarman parameter group names for this sensor group.
    ///
    /// Maps our functional `SensorGroup` enum to upstream YAML group names.
    /// Some of our groups map to multiple upstream groups (e.g., `.inverter` maps
    /// to both "Info" and "Inverter" upstream groups).
    public var upstreamGroupNames: [String] {
        switch self {
        case .battery:
            ["Battery", "Battery Energy", "Battery Meter", "Meter", "meter"]
        case .grid:
            [
                "Grid", "grid", "AC", "Power Grid", "GridEPS",
                "Active Power", "Apparent Power", "Reactive Power", "Power Factor",
                "Voltage", "Current", "Frequency", "Meter", "meter",
            ]
        case .pv:
            ["PV", "Solar", "DC", "InverterDC", "Production", "Meter", "meter"]
        case .load:
            [
                "Load", "load", "Consumption", "Electricity Consumption", "Output", "output", "Meter",
                "meter",
            ]
        case .inverter:
            [
                "Info", "info", "Inverter", "Device",
                "Inverter Information", "InverterAC", "InverterStatus",
                "Control", "Status", "State",
            ]
        case .generator:
            ["Generator", "Gen", "Generator/SmartLoad/Microinverter", "Meter", "meter"]
        case .ups:
            ["UPS", "Backup", "Output", "output", "EPS", "GridEPS"]
        case .bms:
            [
                "BMS", "Battery Management", "Battery Module",
                "Battery 1", "Battery 2", "Battery 3", "Battery 4",
                "Battery 5", "Battery 6", "Battery 7", "Battery 8",
            ]
        case .timeOfUse:
            ["Time of Use", "Schedule", "TOU", "Timed", "Work Mode"]
        case .settings:
            [
                "Settings", "Parameters", "Configuration", "Work Mode", "Grid Parameters",
                "Passive mode settings",
            ]
        case .alerts:
            ["Alerts", "Alarm", "Fault", "faults", "State"]
        case .computed:
            ["Computed", "Calculated", "Losses", "Other", "Energy"]
        }
    }
}
