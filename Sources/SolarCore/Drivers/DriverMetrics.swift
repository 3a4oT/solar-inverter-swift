// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

import Metrics

// MARK: - DriverMetrics

/// Metrics for solar driver operations.
///
/// Uses swift-metrics for portable observability.
/// Compatible with Prometheus, StatsD, CloudWatch, etc.
///
/// ## Metric Names
///
/// | Metric | Type | Description |
/// |--------|------|-------------|
/// | `solar_read_duration_seconds` | Timer | Time to complete read operation |
/// | `solar_read_total` | Counter | Total read operations |
/// | `solar_read_errors_total` | Counter | Read errors by type |
/// | `solar_registers_read_total` | Counter | Total registers read |
/// | `solar_batches_total` | Counter | Total batch requests |
///
/// ## Usage
///
/// ```swift
/// let metrics = DriverMetrics(prefix: "solar")
/// let driver = SolarmanDriver(client: client, metrics: metrics)
/// ```
public struct DriverMetrics: Sendable {
    // MARK: Lifecycle

    /// Creates driver metrics with optional prefix.
    ///
    /// - Parameter prefix: Metric name prefix (default: "solar")
    public init(prefix: String = "solar") {
        self.prefix = prefix
        readDuration = Timer(label: "\(prefix)_read_duration_seconds")
        readTotal = Counter(label: "\(prefix)_read_total")
        registersRead = Counter(label: "\(prefix)_registers_read_total")
        batchesTotal = Counter(label: "\(prefix)_batches_total")
    }

    // MARK: Public

    /// Record successful read operation.
    ///
    /// - Parameters:
    ///   - duration: Time taken in nanoseconds
    ///   - registers: Number of registers read
    ///   - batches: Number of batch requests made
    public func recordRead(duration: UInt64, registers: Int, batches: Int) {
        readDuration.recordNanoseconds(Int64(duration))
        readTotal.increment()
        registersRead.increment(by: registers)
        batchesTotal.increment(by: batches)
    }

    /// Record read error.
    ///
    /// - Parameter error: The error that occurred
    public func recordError(_ error: DriverError) {
        // Create labeled counter for this error type
        let counter = Counter(
            label: "\(prefix)_read_errors_total",
            dimensions: [("error", error.metricsLabel)],
        )
        counter.increment()
    }

    // MARK: Private

    private let prefix: String
    private let readDuration: Timer
    private let readTotal: Counter
    private let registersRead: Counter
    private let batchesTotal: Counter
}

// MARK: - Error Metrics Label

extension DriverError {
    /// Short label for metrics dimension.
    var metricsLabel: String {
        switch self {
        case .connectionFailed: "connection_failed"
        case .timeout: "timeout"
        case .communicationError: "communication_error"
        case .invalidResponse: "invalid_response"
        case .sensorError: "sensor_error"
        case .profileError: "profile_error"
        case .noSensorsForGroups: "no_sensors"
        }
    }
}
