// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - ProfileInfo

/// Device information from upstream ha-solarman format.
///
/// Matches the `info` section in upstream YAML profiles.
///
/// ## Example YAML
///
/// ```yaml
/// # Single model
/// info:
///   manufacturer: Deye
///   model: SG0*LP1
///
/// # Multiple models
/// info:
///   manufacturer: Deye
///   model: [SG0*LP3, SG0*HP3]
/// ```
public struct ProfileInfo: Sendable, Equatable {
    // MARK: Lifecycle

    public init(manufacturer: String, model: String) {
        self.manufacturer = manufacturer
        models = [model]
    }

    public init(manufacturer: String, models: [String]) {
        self.manufacturer = manufacturer
        self.models = models
    }

    // MARK: Public

    /// Manufacturer name (e.g., "Deye", "Solis", "Sofar").
    public let manufacturer: String

    /// Model patterns (supports wildcards, e.g., "SG0*LP1").
    public let models: [String]

    /// Primary model pattern (first in list).
    public var model: String {
        models.first ?? ""
    }
}

// MARK: Codable

extension ProfileInfo: Codable {
    // MARK: Lifecycle

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        manufacturer = try container.decode(String.self, forKey: .manufacturer)

        // Support both String and [String] for model field
        if let singleModel = try? container.decode(String.self, forKey: .model) {
            models = [singleModel]
        } else if let modelArray = try? container.decode([String].self, forKey: .model) {
            models = modelArray
        } else {
            throw DecodingError.typeMismatch(
                String.self,
                DecodingError.Context(
                    codingPath: container.codingPath + [CodingKeys.model],
                    debugDescription: "Expected String or [String] for model",
                ),
            )
        }
    }

    // MARK: Public

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(manufacturer, forKey: .manufacturer)
        if models.count == 1 {
            try container.encode(models[0], forKey: .model)
        } else {
            try container.encode(models, forKey: .model)
        }
    }

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case manufacturer
        case model
    }
}
