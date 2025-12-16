// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - ProfileError

/// Errors related to inverter profile operations.
///
/// These errors occur during device identification and profile matching.
/// Error messages are intentionally kept as structured data (not localized strings)
/// to allow consumers (CLI, apps) to format them appropriately for their locale.
///
/// ## Example
///
/// ```swift
/// do {
///     let profile = try registry.requireProfile(for: device)
/// } catch let error as ProfileError {
///     switch error {
///     case .unsupportedDevice(let device, let suggestion):
///         // Format for user's locale in CLI/App
///         print(formatter.formatUnsupportedDevice(device, suggestion: suggestion))
///     case .unknownDevice(let device):
///         print(formatter.formatUnknownDevice(device))
///     case .profileLoadFailed(let id, let reason):
///         print(formatter.formatLoadError(id, reason: reason))
///     }
/// }
/// ```
public enum ProfileError: Error, Sendable, Equatable {
    /// Device is recognized but not supported.
    ///
    /// - Parameters:
    ///   - device: The identified device information.
    ///   - suggestion: A potentially compatible profile, if available.
    case unsupportedDevice(device: DeviceInfo, suggestion: ProfileReference?)

    /// Device could not be identified.
    ///
    /// - Parameter device: Partial device information that was read.
    case unknownDevice(device: DeviceInfo)

    /// Failed to load profile from storage.
    ///
    /// - Parameters:
    ///   - profileId: The profile identifier that failed to load.
    ///   - reason: Description of the failure.
    case profileLoadFailed(profileId: String, reason: String)

    /// Profile YAML parsing failed.
    ///
    /// - Parameters:
    ///   - profileId: The profile identifier.
    ///   - line: Line number where error occurred (if available).
    ///   - reason: Description of the parsing error.
    case profileParseError(profileId: String, line: Int?, reason: String)

    /// Device communication failed during identification.
    ///
    /// - Parameter reason: Description of the communication error.
    case identificationFailed(reason: String)
}

// MARK: - Error Context for Consumers

extension ProfileError {
    /// URL for reporting unsupported devices.
    public static let issueReportURL =
        "https://github.com/3a4oT/solar-inverter-swift/issues/new?template=device-support.md"

    /// Device information associated with this error (if available).
    public var device: DeviceInfo? {
        switch self {
        case let .unsupportedDevice(device, _):
            device
        case let .unknownDevice(device):
            device
        case .profileLoadFailed,
             .profileParseError,
             .identificationFailed:
            nil
        }
    }

    /// Suggested profile for recovery (if available).
    public var suggestedProfile: ProfileReference? {
        switch self {
        case let .unsupportedDevice(_, suggestion):
            suggestion
        default:
            nil
        }
    }

    /// Profile identifier associated with this error (if available).
    public var profileId: String? {
        switch self {
        case let .profileLoadFailed(id, _):
            id
        case let .profileParseError(id, _, _):
            id
        default:
            nil
        }
    }

    /// Whether this error might be recoverable by trying a different profile.
    public var isRecoverable: Bool {
        switch self {
        case .unsupportedDevice(_, .some):
            true
        default:
            false
        }
    }
}
