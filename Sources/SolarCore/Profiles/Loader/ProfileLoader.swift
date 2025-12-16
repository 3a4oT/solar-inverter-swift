// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// Bundle is only available in Foundation (not FoundationEssentials)
import Foundation
import Yams

// MARK: - ProfileLoader

/// Loads inverter profiles from YAML files (ha-solarman format).
///
/// Profiles use upstream ha-solarman YAML format with `info`, `default`, and `parameters`.
/// See: https://github.com/davidrapan/ha-solarman
///
/// Supports loading from:
/// - Bundled resources via type-safe ``ProfileID``
/// - Bundled resources by string ID
/// - Local file paths
/// - YAML strings via ``parse(yaml:profileId:)`` (for remote URLs, databases, etc.)
///
/// ## Example
///
/// ```swift
/// let loader = ProfileLoader()
///
/// // Type-safe bundled profile (recommended)
/// let deye = try loader.load(.deyeHybridSinglePhase)
///
/// // String-based bundled profile
/// let deye2 = try loader.load(id: "deye_hybrid")
///
/// // Load from local file
/// let custom = try loader.load(from: "/path/to/custom_profile.yaml")
///
/// // Parse from YAML string (for remote sources)
/// let yaml = try await fetchYAMLFromRemote(url)
/// let remote = try loader.parse(yaml: yaml, profileId: "remote")
///
/// // List all bundled profiles
/// let profiles = ProfileID.allCases
/// ```
public struct ProfileLoader: Sendable {
    // MARK: Lifecycle

    public init(bundle: Bundle? = nil) {
        self.bundle = bundle ?? Bundle.module
    }

    // MARK: Public

    /// Maximum allowed YAML size in bytes (256KB).
    ///
    /// Protects against memory exhaustion from malformed or malicious input.
    /// Typical profiles are 10-50KB; 256KB allows for very large profiles with headroom.
    public static let maxYAMLSize = 262_144

    /// All manufacturer directories to search for profiles.
    ///
    /// This includes both known ProfileID manufacturers and additional
    /// upstream ha-solarman manufacturers for custom profile support.
    public static let allManufacturers = [
        "afore", "aiswei", "cns", "cotek", "deye", "givenergy",
        "growatt", "hinen", "hosola", "kstar", "livoltek", "lsw",
        "saj", "sofar", "solis", "srne", "swatten", "zcs",
    ]

    /// Shared instance using default resource bundle.
    public static let shared = ProfileLoader()

    // MARK: - Type-Safe Loading (Recommended)

    /// Load a bundled profile by type-safe ID.
    ///
    /// This is the recommended way to load bundled profiles.
    ///
    /// - Parameter profileId: Type-safe profile identifier.
    /// - Returns: Loaded inverter definition.
    /// - Throws: `ProfileError` if not found or invalid.
    public func load(_ profileId: ProfileID) throws(ProfileError) -> InverterDefinition {
        let resourcePath = "Resources/\(profileId.manufacturer)/\(profileId.id)"

        guard let url = bundle.url(forResource: resourcePath, withExtension: "yaml") else {
            throw .profileLoadFailed(
                profileId: profileId.id,
                reason: "Profile '\(profileId.displayName)' not found in bundle",
            )
        }

        return try load(from: url, profileId: profileId.id)
    }

    // MARK: - String-Based Loading

    /// Load a profile by string ID from bundled resources.
    ///
    /// Searches in manufacturer subdirectories: `deye/`, `solis/`, `sofar/`, etc.
    ///
    /// - Parameter id: Profile identifier (e.g., "deye_sg04lp3").
    /// - Returns: Loaded inverter definition.
    /// - Throws: `ProfileError` if not found or invalid.
    public func load(id: String) throws(ProfileError) -> InverterDefinition {
        // Check if it matches a known ProfileID
        if let profileId = ProfileID(rawValue: id) {
            return try load(profileId)
        }

        // Search in manufacturer directories for custom profiles
        for manufacturer in Self.allManufacturers {
            let resourcePath = "Resources/\(manufacturer)/\(id)"
            if let url = bundle.url(forResource: resourcePath, withExtension: "yaml") {
                return try load(from: url, profileId: id)
            }
        }

        // Try root Resources directory
        if let url = bundle.url(forResource: "Resources/\(id)", withExtension: "yaml") {
            return try load(from: url, profileId: id)
        }

        throw .profileLoadFailed(profileId: id, reason: "Profile not found in bundle")
    }

    /// Load a profile from a local file URL.
    ///
    /// - Parameters:
    ///   - url: Local file URL to YAML profile.
    ///   - profileId: Optional ID override (defaults to filename).
    /// - Returns: Loaded inverter definition.
    /// - Throws: `ProfileError` if file cannot be read or parsed.
    public func load(from url: URL, profileId: String? = nil) throws(ProfileError)
        -> InverterDefinition {
        let id = profileId ?? url.extractProfileId()

        let yaml: String
        do {
            yaml = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw .profileLoadFailed(
                profileId: id, reason: "Cannot read file: \(error.localizedDescription)",
            )
        }

        return try parse(yaml: yaml, profileId: id)
    }

    /// Load a profile from a file path string.
    ///
    /// - Parameter path: Path to YAML profile file.
    /// - Returns: Loaded inverter definition.
    /// - Throws: `ProfileError` if file cannot be read or parsed.
    public func load(from path: String) throws(ProfileError) -> InverterDefinition {
        let url = URL(fileURLWithPath: path)
        return try load(from: url)
    }

    /// Parse profile from a UTF-8 YAML string.
    ///
    /// Use this method when loading profiles from external sources (remote URL, database,
    /// user input). The caller is responsible for fetching raw bytes and converting to `String`.
    ///
    /// - Parameters:
    ///   - yaml: UTF-8 encoded YAML string. Must not exceed ``maxYAMLSize`` (256KB).
    ///   - profileId: Identifier for error messages (filename, URL, or custom ID).
    /// - Returns: Parsed inverter definition.
    /// - Throws: ``ProfileError/profileParseError(profileId:line:reason:)`` if YAML is invalid,
    ///           too large, or missing required fields.
    ///
    /// ## Size Limit
    ///
    /// Input is validated against ``maxYAMLSize`` (256KB) to prevent memory exhaustion.
    /// Typical profiles are 10-50KB.
    ///
    /// ## Converting Bytes to String
    ///
    /// ```swift
    /// // From Data (Foundation)
    /// let yaml = String(decoding: data, as: UTF8.self)
    ///
    /// // From [UInt8]
    /// let yaml = String(decoding: bytes, as: UTF8.self)
    ///
    /// // From ByteBuffer (SwiftNIO)
    /// let yaml = buffer.getString(at: 0, length: buffer.readableBytes) ?? ""
    /// ```
    ///
    /// ## Remote URL Example (AsyncHTTPClient)
    ///
    /// ```swift
    /// let response = try await httpClient.execute(
    ///     request: HTTPClientRequest(url: profileURL),
    ///     timeout: .seconds(30)
    /// )
    /// let body = try await response.body.collect(upTo: ProfileLoader.maxYAMLSize)
    /// let yaml = String(buffer: body)
    /// let profile = try loader.parse(yaml: yaml, profileId: "remote")
    /// ```
    ///
    /// ## Remote URL Example (URLSession)
    ///
    /// ```swift
    /// let (data, _) = try await URLSession.shared.data(from: profileURL)
    /// let yaml = String(decoding: data, as: UTF8.self)
    /// let profile = try loader.parse(yaml: yaml, profileId: "remote")
    /// ```
    public func parse(yaml: String, profileId: String) throws(ProfileError) -> InverterDefinition {
        // Validate size to prevent memory exhaustion
        guard yaml.utf8.count <= Self.maxYAMLSize else {
            throw .profileParseError(
                profileId: profileId,
                line: nil,
                reason: "YAML exceeds \(Self.maxYAMLSize / 1024)KB limit",
            )
        }

        let decoder = YAMLDecoder()

        do {
            return try decoder.decode(InverterDefinition.self, from: yaml)
        } catch let error as DecodingError {
            let (line, reason) = extractDecodingErrorInfo(error)
            throw .profileParseError(profileId: profileId, line: line, reason: reason)
        } catch {
            throw .profileParseError(profileId: profileId, line: nil, reason: error.localizedDescription)
        }
    }

    /// List all available bundled profile IDs.
    ///
    /// - Returns: Array of profile IDs.
    public func availableProfiles() -> [String] {
        var profiles: [String] = []

        for manufacturer in Self.allManufacturers {
            if let urls = bundle.urls(
                forResourcesWithExtension: "yaml", subdirectory: "Resources/\(manufacturer)",
            ) {
                for url in urls {
                    profiles.append(url.extractProfileId())
                }
            }
        }

        return profiles.sorted()
    }

    /// Load all available bundled profiles.
    ///
    /// - Returns: Array of loaded inverter definitions (skips invalid ones).
    public func loadAllProfiles() -> [InverterDefinition] {
        availableProfiles().compactMap { id in
            try? load(id: id)
        }
    }

    // MARK: Private

    /// Bundle containing profile resources.
    private let bundle: Bundle

    private func extractDecodingErrorInfo(_ error: DecodingError) -> (line: Int?, reason: String) {
        switch error {
        case let .keyNotFound(key, context):
            return (
                nil,
                "Missing key '\(key.stringValue)' at \(context.codingPath.map(\.stringValue).joined(separator: "."))",
            )

        case let .typeMismatch(type, context):
            return (
                nil,
                "Type mismatch for \(type) at \(context.codingPath.map(\.stringValue).joined(separator: "."))",
            )

        case let .valueNotFound(type, context):
            return (
                nil,
                "Missing value for \(type) at \(context.codingPath.map(\.stringValue).joined(separator: "."))",
            )

        case let .dataCorrupted(context):
            return (
                nil,
                "Corrupted data at \(context.codingPath.map(\.stringValue).joined(separator: ".")): \(context.debugDescription)",
            )

        @unknown default:
            return (nil, error.localizedDescription)
        }
    }
}

// MARK: - URL + Profile ID

extension URL {
    /// Extracts profile ID from URL path.
    ///
    /// Uses `path` property and string parsing to avoid cross-platform
    /// inconsistencies with `lastPathComponent` and `deletingPathExtension`.
    func extractProfileId() -> String {
        // Get path and extract filename
        let pathString = path
        let filename = pathString.split(separator: "/").last.map(String.init) ?? pathString

        // Remove .yaml extension
        if filename.hasSuffix(".yaml") {
            return String(filename.dropLast(5))
        }
        return filename
    }
}

// MARK: - NSURL + Profile ID (Linux compatibility)

#if !canImport(Darwin)
    extension NSURL {
        /// Extracts profile ID from URL path.
        ///
        /// On Linux, `Bundle.urls(...)` returns `[NSURL]?` instead of `[URL]?`.
        func extractProfileId() -> String {
            guard let pathString = path else {
                return ""
            }
            let filename = pathString.split(separator: "/").last.map(String.init) ?? pathString

            if filename.hasSuffix(".yaml") {
                return String(filename.dropLast(5))
            }
            return filename
        }
    }
#endif
