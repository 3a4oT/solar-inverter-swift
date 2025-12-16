// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - ProfileMatch

/// Result of profile lookup for a device.
///
/// Used by `ProfileRegistry.find(for:)` to indicate whether
/// a matching profile was found, and provide suggestions if not.
public enum ProfileMatch: Sendable, Equatable {
    /// Profile found for this exact device.
    case found(ProfileReference)

    /// Device recognized but not fully supported.
    /// Includes a suggested compatible profile if available.
    case unsupported(suggestion: ProfileReference?)

    /// Device not recognized at all.
    case unknown
}

// MARK: - ProfileReference

/// Reference to an inverter profile.
///
/// Lightweight identifier used before full profile loading.
public struct ProfileReference: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    /// Creates a profile reference.
    public init(
        id: String,
        name: String,
        manufacturer: String,
        modelPattern: String,
    ) {
        self.id = id
        self.name = name
        self.manufacturer = manufacturer
        self.modelPattern = modelPattern
    }

    // MARK: Public

    /// Profile identifier (e.g., "deye/sg01hp3").
    public let id: String

    /// Human-readable profile name.
    public let name: String

    /// Manufacturer this profile supports.
    public let manufacturer: String

    /// Model pattern this profile matches (may include wildcards).
    public let modelPattern: String
}
