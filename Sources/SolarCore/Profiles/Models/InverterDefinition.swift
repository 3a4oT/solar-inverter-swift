// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - InverterDefinition

/// Inverter definition in upstream ha-solarman format.
///
/// This is the main profile model that matches the upstream YAML structure exactly.
/// Use this for loading profiles synced from ha-solarman repository.
///
/// ## Example YAML
///
/// ```yaml
/// info:
///   manufacturer: Deye
///   model: SG0*LP1
///
/// default:
///   update_interval: 5
///   digits: 6
///
/// parameters:
///   - group: Battery
///     items:
///       - name: "Battery SOC"
///         rule: 1
///         registers: [0x00B8]
///         uom: "%"
/// ```
///
/// ## Upstream Repository
///
/// https://github.com/davidrapan/ha-solarman
public struct InverterDefinition: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    public init(
        info: ProfileInfo,
        default: ProfileDefaults? = nil,
        parameters: [ParameterGroup],
    ) {
        self.info = info
        self.default = `default`
        self.parameters = parameters
    }

    // MARK: Public

    /// Device identification.
    public let info: ProfileInfo

    /// Default settings.
    public let `default`: ProfileDefaults?

    /// Parameter groups containing sensor items.
    public let parameters: [ParameterGroup]
}

// MARK: - Convenience Accessors

extension InverterDefinition {
    /// Manufacturer name.
    public var manufacturer: String {
        info.manufacturer
    }

    /// Model pattern.
    public var model: String {
        info.model
    }

    /// Default update interval.
    public var updateInterval: Int {
        `default`?.updateInterval ?? 5
    }

    /// Default decimal digits.
    public var digits: Int {
        `default`?.digits ?? 6
    }

    /// All sensor items as flat array.
    public var allItems: [SensorItem] {
        parameters.flatMap(\.items)
    }

    /// All read-only sensors.
    public var allSensors: [SensorItem] {
        allItems.filter(\.isReadOnly)
    }

    /// All writable items.
    public var allWritableItems: [SensorItem] {
        allItems.filter { !$0.isReadOnly }
    }

    /// Total number of items.
    public var itemCount: Int {
        allItems.count
    }

    /// All register addresses.
    public var allRegisters: [UInt16] {
        allItems.flatMap(\.registers)
    }

    /// All unique register addresses sorted.
    public var uniqueRegisters: [UInt16] {
        Array(Set(allRegisters)).sorted()
    }
}

// MARK: - Group Access

extension InverterDefinition {
    /// All group names.
    public var groupNames: [String] {
        parameters.map(\.group)
    }

    /// Find group by name (case-insensitive).
    public func group(named name: String) -> ParameterGroup? {
        parameters.first { $0.matches(name: name) }
    }

    /// Get all items from a group.
    public func items(inGroup name: String) -> [SensorItem] {
        group(named: name)?.items ?? []
    }

    /// Get sensor by name.
    public func sensor(named name: String) -> SensorItem? {
        allItems.first { $0.name == name }
    }
}

// MARK: - Common Groups

extension InverterDefinition {
    /// Battery-related sensors.
    public var batterySensors: [SensorItem] {
        items(inGroup: "Battery")
    }

    /// PV/Solar sensors.
    public var pvSensors: [SensorItem] {
        items(inGroup: "PV")
    }

    /// Grid sensors.
    public var gridSensors: [SensorItem] {
        items(inGroup: "Grid")
    }

    /// Load/consumption sensors.
    public var loadSensors: [SensorItem] {
        items(inGroup: "Load")
    }

    /// Inverter info/status sensors.
    public var inverterSensors: [SensorItem] {
        items(inGroup: "Info") + items(inGroup: "Inverter") + items(inGroup: "Control")
    }

    /// BMS sensors.
    public var bmsSensors: [SensorItem] {
        items(inGroup: "BMS")
    }

    /// Settings (writable parameters).
    public var settings: [SensorItem] {
        items(inGroup: "Settings") + items(inGroup: "Parameters")
    }
}
