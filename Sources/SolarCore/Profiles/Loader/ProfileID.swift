// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - ProfileID

/// Type-safe identifier for bundled inverter profiles.
///
/// Provides compile-time safety for profile selection instead of raw strings.
///
/// ## Usage
///
/// ```swift
/// let loader = ProfileLoader()
///
/// // Type-safe (recommended)
/// let profile = try loader.load(.deyeHybridSinglePhase)
///
/// // Still supports string for custom profiles
/// let custom = try loader.load(id: "custom_profile")
/// ```
///
/// ## Adding New Profiles
///
/// 1. Add YAML file to `Resources/{manufacturer}/`
/// 2. Add case to this enum
/// 3. Update `id` and `manufacturer` computed properties
public enum ProfileID: String, Sendable, CaseIterable {
    // MARK: - Deye

    /// Deye single-phase hybrid inverters (SUN-*-SG03LP1, etc.)
    case deyeHybridSinglePhase = "deye_hybrid"

    /// Deye three-phase hybrid inverters (SUN-*-SG04LP3, SUN-*-SG01HP3, etc.)
    case deyeHybridThreePhase = "deye_p3"

    /// Deye string inverters (grid-tie, no battery)
    case deyeString = "deye_string"

    /// Deye micro inverters
    case deyeMicro = "deye_micro"

    // MARK: - Solis

    /// Solis hybrid inverters
    case solisHybrid = "solis_hybrid"

    /// Solis string inverters
    case solisString = "solis_string"

    // MARK: - Sofar

    /// Sofar hybrid inverters
    case sofarHybrid = "sofar_hybrid"

    // MARK: Public

    /// Profile filename (without extension).
    public var id: String { rawValue }

    /// Manufacturer directory name.
    public var manufacturer: String {
        switch self {
        case .deyeHybridSinglePhase,
             .deyeHybridThreePhase,
             .deyeString,
             .deyeMicro:
            "deye"
        case .solisHybrid,
             .solisString:
            "solis"
        case .sofarHybrid:
            "sofar"
        }
    }

    /// Human-readable display name.
    public var displayName: String {
        switch self {
        case .deyeHybridSinglePhase: "Deye Hybrid (1P)"
        case .deyeHybridThreePhase: "Deye Hybrid (3P)"
        case .deyeString: "Deye String"
        case .deyeMicro: "Deye Micro"
        case .solisHybrid: "Solis Hybrid"
        case .solisString: "Solis String"
        case .sofarHybrid: "Sofar Hybrid"
        }
    }
}

// MARK: - Manufacturer Grouping

extension ProfileID {
    /// All available manufacturers.
    public static var manufacturers: [String] {
        Array(Set(allCases.map(\.manufacturer))).sorted()
    }

    /// All profiles for a specific manufacturer.
    public static func profiles(for manufacturer: String) -> [ProfileID] {
        allCases.filter { $0.manufacturer == manufacturer }
    }
}
