// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

/// Default settings from upstream ha-solarman format.
///
/// Matches the `default` section in upstream YAML profiles.
///
/// ## Example YAML
///
/// ```yaml
/// default:
///   update_interval: 5
///   digits: 6
/// ```
public struct ProfileDefaults: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    public init(updateInterval: Int = 5, digits: Int = 6) {
        self.updateInterval = updateInterval
        self.digits = digits
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        updateInterval = try container.decodeIfPresent(Int.self, forKey: .updateInterval) ?? 5
        digits = try container.decodeIfPresent(Int.self, forKey: .digits) ?? 6
    }

    // MARK: Public

    /// Default polling interval in seconds.
    public let updateInterval: Int

    /// Default decimal precision for values.
    public let digits: Int

    // MARK: Internal

    enum CodingKeys: String, CodingKey {
        case updateInterval = "update_interval"
        case digits
    }
}
