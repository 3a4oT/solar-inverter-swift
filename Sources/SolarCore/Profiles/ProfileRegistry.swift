// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - ProfileRegistry

/// Registry of available inverter profiles.
///
/// Provides automatic profile lookup based on device identification.
/// Profiles are loaded from YAML files in the Resources/Profiles directory.
///
/// ## Example
///
/// ```swift
/// let registry = ProfileRegistry.shared
///
/// // Find profile for a device
/// let device = DeviceInfo(manufacturer: "DEYE", model: "SUN-12K-SG01HP3-EU", serial: "...")
/// switch registry.find(for: device) {
/// case .found(let profile):
///     print("Using profile: \(profile.name)")
/// case .unsupported(let suggestion):
///     if let suggestion {
///         print("Try compatible profile: \(suggestion.name)")
///     }
/// case .unknown:
///     print("Unknown device")
/// }
///
/// // List all supported manufacturers
/// print(registry.supportedManufacturers)
/// // ["DEYE", "SOLIS", "VICTRON"]
/// ```
public final class ProfileRegistry: Sendable {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Creates a registry with the given profiles.
    public init(profiles: [ProfileReference] = []) {
        self.profiles = profiles
    }

    // MARK: Public

    // MARK: - Security Limits

    /// Maximum allowed length for device identifiers.
    /// Prevents memory exhaustion from malicious input.
    public static let maxIdentifierLength = 128

    /// Shared registry instance.
    public static let shared = ProfileRegistry()

    /// All registered profile references.
    public let profiles: [ProfileReference]

    /// List of supported manufacturer names.
    public var supportedManufacturers: [String] {
        Array(Set(profiles.map(\.manufacturer))).sorted()
    }

    /// List of all supported model patterns.
    public var supportedModels: [String] {
        profiles.map(\.modelPattern).sorted()
    }

    // MARK: - Profile Lookup

    /// Find a matching profile for the given device.
    ///
    /// - Parameter device: Device information from inverter.
    /// - Returns: Match result indicating found, unsupported, or unknown.
    ///
    /// ## Security
    /// - Rejects control characters (C0, DEL, C1) in identifiers
    /// - Enforces length limits to prevent memory exhaustion
    /// - Uses bounded pattern matching to prevent algorithmic attacks
    public func find(for device: DeviceInfo) -> ProfileMatch {
        // Input validation — reject control characters and oversized identifiers
        guard
            device.manufacturer.hasNoControlCharacters,
            device.model.hasNoControlCharacters,
            device.manufacturer.count <= Self.maxIdentifierLength,
            device.model.count <= Self.maxIdentifierLength
        else {
            return .unknown
        }

        // Normalize for case-insensitive matching
        let normalizedManufacturer = device.manufacturer.lowercased()
        let normalizedModel = device.model.lowercased()

        // Exact match first (O(n) where n = profile count)
        for profile in profiles {
            guard profile.manufacturer.lowercased() == normalizedManufacturer else {
                continue
            }
            if profile.modelPattern.lowercased() == normalizedModel {
                return .found(profile)
            }
        }

        // Pattern match with bounded complexity
        for profile in profiles {
            guard profile.manufacturer.lowercased() == normalizedManufacturer else {
                continue
            }
            if matchesPatternBounded(
                pattern: profile.modelPattern.lowercased(),
                value: normalizedModel,
            ) {
                return .found(profile)
            }
        }

        // Suggestion from same manufacturer
        let suggestion = profiles.first {
            $0.manufacturer.lowercased() == normalizedManufacturer
        }
        if suggestion != nil {
            return .unsupported(suggestion: suggestion)
        }

        return .unknown
    }

    // MARK: Private

    /// Maximum iterations for pattern matching.
    /// Prevents algorithmic complexity attacks.
    private static let maxPatternIterations = 100

    // MARK: - Private Pattern Matching

    /// Bounded wildcard matching — O(n) worst case.
    ///
    /// Supports simple `*` wildcards only (no regex).
    /// Pattern `SUN-*-SG01HP3*` matches `SUN-12K-SG01HP3-EU`.
    ///
    /// - Parameters:
    ///   - pattern: Pattern with optional `*` wildcards.
    ///   - value: Value to match against.
    /// - Returns: True if value matches pattern.
    private func matchesPatternBounded(pattern: String, value: String) -> Bool {
        // No wildcards — exact match already handled above
        guard pattern.contains("*") else {
            return pattern == value
        }

        let parts = pattern.split(separator: "*", omittingEmptySubsequences: false)

        // Empty pattern with just "*" matches everything
        if parts.allSatisfy(\.isEmpty) {
            return true
        }

        var valueIndex = value.startIndex
        var iterations = 0

        for (partIndex, part) in parts.enumerated() {
            // Bound iterations to prevent algorithmic attacks
            iterations += 1
            if iterations > Self.maxPatternIterations {
                return false
            }

            // Empty part (from consecutive ** or leading/trailing *)
            guard !part.isEmpty else {
                continue
            }

            let partString = String(part)

            // Find this part in remaining value
            guard
                let range = value.range(
                    of: partString,
                    range: valueIndex..<value.endIndex,
                )
            else {
                return false
            }

            // First part must match at start (unless pattern starts with *)
            if partIndex == 0, range.lowerBound != value.startIndex {
                return false
            }

            // Last part must match at end (unless pattern ends with *)
            if partIndex == parts.count - 1, range.upperBound != value.endIndex {
                return false
            }

            valueIndex = range.upperBound
        }

        return true
    }
}

// MARK: - String Security Validation

extension String {
    /// Returns true if string contains no control characters.
    ///
    /// Control characters include:
    /// - C0 controls: U+0000-U+001F
    /// - DEL: U+007F
    /// - C1 controls: U+0080-U+009F
    ///
    /// Used for security validation of device identifiers.
    /// UTF-8 identifiers are allowed (modern devices may have Unicode names),
    /// but control characters are rejected for security.
    var hasNoControlCharacters: Bool {
        unicodeScalars.allSatisfy { scalar in
            let value = scalar.value
            // Reject C0 controls (0x00-0x1F), DEL (0x7F), C1 controls (0x80-0x9F)
            return value >= 0x20 && value != 0x7F && (value < 0x80 || value > 0x9F)
        }
    }
}
