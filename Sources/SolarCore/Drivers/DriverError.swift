// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - DriverError

/// Errors from driver operations.
public enum DriverError: Error, Sendable, Equatable {
    /// Connection to inverter failed.
    case connectionFailed(String)

    /// Operation timed out.
    case timeout

    /// Communication error during read/write.
    case communicationError(String)

    /// Invalid or malformed response.
    case invalidResponse(String)

    /// Sensor conversion error.
    case sensorError(SensorError)

    /// Profile error (missing sensor, invalid config).
    case profileError(String)

    /// No sensors found for requested groups.
    case noSensorsForGroups(Set<SensorGroup>)
}

// MARK: - Retry Classification

extension DriverError {
    /// Whether this error is potentially recoverable with retry.
    public var isRetryable: Bool {
        switch self {
        case .timeout,
             .communicationError:
            true
        case .connectionFailed,
             .invalidResponse,
             .sensorError,
             .profileError,
             .noSensorsForGroups:
            false
        }
    }
}
