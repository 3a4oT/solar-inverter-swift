// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - ParameterGroup

/// Parameter group from upstream ha-solarman format.
///
/// Groups related sensors together with optional custom update interval.
///
/// ## Example YAML
///
/// ```yaml
/// parameters:
///   - group: Battery
///     update_interval: 5
///     items:
///       - name: "Battery SOC"
///         rule: 1
///         registers: [0x00B8]
///         uom: "%"
/// ```
public struct ParameterGroup: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    public init(
        group: String,
        updateInterval: Int? = nil,
        items: [SensorItem],
    ) {
        self.group = group
        self.updateInterval = updateInterval
        self.items = items
    }

    // MARK: Public

    /// Group name (e.g., "Battery", "PV", "Grid").
    public let group: String

    /// Custom update interval (overrides default).
    public let updateInterval: Int?

    /// Sensor items in this group.
    public let items: [SensorItem]

    // MARK: Internal

    enum CodingKeys: String, CodingKey {
        case group
        case updateInterval = "update_interval"
        case items
    }
}

// MARK: - Convenience

extension ParameterGroup {
    /// Number of sensors in this group.
    public var count: Int {
        items.count
    }

    /// All register addresses in this group.
    public var allRegisters: [UInt16] {
        items.flatMap(\.registers)
    }

    /// Filter read-only sensors.
    public var sensors: [SensorItem] {
        items.filter(\.isReadOnly)
    }

    /// Filter writable items.
    public var writableItems: [SensorItem] {
        items.filter { !$0.isReadOnly }
    }

    /// Filter items by platform.
    public func items(platform: Platform) -> [SensorItem] {
        items.filter { $0.platform == platform }
    }
}

// MARK: - Group Name Normalization

extension ParameterGroup {
    /// Normalized group name for matching.
    public var normalizedGroup: String {
        group.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
    }

    /// Check if this group matches a name (case-insensitive).
    public func matches(name: String) -> Bool {
        normalizedGroup
            == name.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
    }
}
