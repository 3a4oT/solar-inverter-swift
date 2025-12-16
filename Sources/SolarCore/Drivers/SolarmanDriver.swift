// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

import Logging
import Metrics
import SolarmanV5

// MARK: - SolarmanDriver

/// Solar driver using Solarman V5 protocol (WiFi data loggers).
///
/// Orchestrates reading from inverters via Solarman V5 client:
/// 1. Batches register addresses from profile
/// 2. Reads via SolarmanClient
/// 3. Converts raw registers to typed values
/// 4. Builds SolarStatus output
///
/// ## Observability
///
/// Supports optional logging and metrics:
/// - **Logger**: `debug` for operation flow, `trace` for batch details
/// - **Metrics**: read duration, register counts, error rates
///
/// ## Usage
///
/// ```swift
/// let client = SolarmanV5Client(host: "192.168.1.100", serial: 1700000001)
/// try await client.connect()
///
/// let driver = SolarmanDriver(
///     client: client,
///     logger: Logger(label: "solar.driver"),
///     metrics: DriverMetrics()
/// )
/// let profile = try profileLoader.load(id: "deye_hybrid")
///
/// let status = try await driver.read(profile: profile, groups: [.battery, .pv])
/// print("SOC: \(status.battery?.soc ?? 0)%")
/// ```
public struct SolarmanDriver: SolarDriver, Sendable {
    // MARK: Lifecycle

    public init(
        client: any SolarmanClient,
        batcher: RegisterBatcher = RegisterBatcher(),
        builder: StatusBuilder = StatusBuilder(),
        logger: Logger? = nil,
        metrics: DriverMetrics? = nil,
    ) {
        self.client = client
        self.batcher = batcher
        self.builder = builder
        self.logger = logger
        self.metrics = metrics
    }

    // MARK: Public

    public func read(
        profile: InverterDefinition,
        groups: Set<SensorGroup>,
    ) async throws(DriverError) -> SolarStatus {
        let startTime = ContinuousClock.now
        let effectiveGroups = groups.isEmpty ? SensorGroup.basic : groups

        // 1. Collect sensors for requested groups
        let items = collectItems(from: profile, groups: effectiveGroups)
        guard !items.isEmpty else {
            let error = DriverError.noSensorsForGroups(effectiveGroups)
            metrics?.recordError(error)
            throw error
        }

        // 2. Batch register addresses
        let ranges = batcher.batch(items: items)

        logger?.debug(
            "Starting read",
            metadata: [
                "profile": "\(profile.model)",
                "sensors": "\(items.count)",
                "batches": "\(ranges.count)",
                "groups": "\(effectiveGroups.map(\.rawValue).joined(separator: ","))",
            ],
        )

        // 3. Read all registers
        let registerValues: [UInt16: UInt16]
        do {
            registerValues = try await readAllRanges(ranges)
        } catch {
            metrics?.recordError(error)
            throw error
        }

        logger?.debug(
            "Registers read",
            metadata: ["count": "\(registerValues.count)"],
        )

        // 4. Build typed status
        let status: SolarStatus
        do {
            status = try builder.build(
                from: registerValues,
                profile: profile,
                groups: effectiveGroups,
            )
        } catch {
            metrics?.recordError(error)
            throw error
        }

        // Record success metrics
        let duration = ContinuousClock.now - startTime
        metrics?.recordRead(
            duration: UInt64(duration.components.attoseconds / 1_000_000_000),
            registers: registerValues.count,
            batches: ranges.count,
        )

        logger?.debug(
            "Read complete",
            metadata: [
                "duration_ms":
                    "\(duration.components.seconds * 1000 + Int64(duration.components.attoseconds / 1_000_000_000_000_000))",
            ],
        )

        return status
    }

    // MARK: Private

    private let client: any SolarmanClient
    private let batcher: RegisterBatcher
    private let builder: StatusBuilder
    private let logger: Logger?
    private let metrics: DriverMetrics?
}

// MARK: - Private Helpers

extension SolarmanDriver {
    /// Collect sensor items from profile for requested groups.
    private func collectItems(
        from profile: InverterDefinition,
        groups: Set<SensorGroup>,
    ) -> [SensorItem] {
        groups.flatMap { group -> [SensorItem] in
            group.upstreamGroupNames.flatMap { profile.items(inGroup: $0) }
        }
    }

    private func readAllRanges(
        _ ranges: [RegisterRange],
    ) async throws(DriverError) -> [UInt16: UInt16] {
        var allRegisters: [UInt16: UInt16] = [:]
        allRegisters.reserveCapacity(ranges.reduce(0) { $0 + $1.count })

        for range in ranges {
            let registers = try await readRange(range)
            for (offset, value) in registers.enumerated() {
                // Safe: offset is bounded by registers.count which comes from Modbus response
                // and range.count is clamped to 125 max in RegisterRange.init
                let address = range.startAddress &+ UInt16(clamping: offset)
                allRegisters[address] = value
            }
        }

        return allRegisters
    }

    private func readRange(_ range: RegisterRange) async throws(DriverError) -> [UInt16] {
        logger?.trace(
            "Reading batch",
            metadata: [
                "start": "\(range.startAddress)",
                "count": "\(range.count)",
            ],
        )

        do {
            let response = try await client.readHoldingRegisters(
                address: range.startAddress,
                count: UInt16(range.count),
            )

            logger?.trace(
                "Batch complete",
                metadata: [
                    "start": "\(range.startAddress)",
                    "registers": "\(response.registers.count)",
                ],
            )

            return response.registers
        } catch {
            throw mapClientError(error)
        }
    }

    private func mapClientError(_ error: SolarmanClientError) -> DriverError {
        switch error {
        case let .connectionFailed(reason):
            .connectionFailed(reason)
        case .timeout:
            .timeout
        case .notConnected,
             .channelClosed:
            .connectionFailed("Not connected")
        case let .v5FrameError(msg),
             let .rtuError(msg):
            .invalidResponse(msg)
        case let .modbusException(exception):
            .invalidResponse("Modbus exception: \(exception)")
        case let .sequenceMismatch(expected, got):
            .invalidResponse("Sequence mismatch: expected \(expected), got \(got)")
        case let .ioError(msg):
            .communicationError(msg)
        case .alreadyConnected:
            .communicationError("Already connected")
        case let .invalidParameter(msg):
            .profileError(msg)
        }
    }
}
