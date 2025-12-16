// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

import Logging
import SolarmanV5

// MARK: - Scoped Driver Helper

/// Executes an operation with a connected Solarman driver, ensuring cleanup.
///
/// Creates a client, connects, loads the profile, executes the operation, and
/// closes the connection regardless of success or failure. Best for one-off
/// operations in CLI tools, scripts, or tests.
///
/// **Example:**
/// ```swift
/// let status = try await withSolarmanDriver(
///     host: "192.168.1.100",
///     serial: 2712345678,
///     profile: .deyeP3
/// ) { driver, profile in
///     try await driver.read(profile: profile, groups: [.battery, .pv])
/// }
/// ```
///
/// - Parameters:
///   - host: Hostname or IP address of the data logging stick
///   - serial: Serial number of the data logging stick (10 digits)
///   - profile: Profile ID to load
///   - port: TCP port (default: 8899)
///   - unitId: Modbus unit ID (default: 1)
///   - timeout: Connection and read timeout (default: 60 seconds)
///   - logger: Optional logger for debugging
///   - metrics: Optional metrics for observability
///   - operation: Async closure to execute with the driver and loaded profile
/// - Returns: The result of the operation
/// - Throws: `DriverError` on connection, profile, or operation failure
public func withSolarmanDriver<Result: Sendable>(
    host: String,
    serial: UInt32,
    profile profileId: ProfileID,
    port: Int = 8899,
    unitId: UInt8 = 1,
    timeout: Duration = .seconds(60),
    logger: Logger? = nil,
    metrics: DriverMetrics? = nil,
    operation: (SolarmanDriver, InverterDefinition) async throws(DriverError) -> Result,
) async throws(DriverError) -> Result {
    // 1. Load profile first (before connecting)
    let loader = ProfileLoader()
    let profile: InverterDefinition
    do {
        profile = try loader.load(profileId)
    } catch {
        throw DriverError.profileError("\(error)")
    }

    // 2. Connect
    let client = SolarmanV5Client(
        host: host,
        serial: serial,
        port: port,
        unitId: unitId,
        timeout: timeout,
        logger: logger,
    )

    do {
        try await client.connect()
    } catch {
        throw DriverError.connectionFailed("\(error)")
    }

    // 3. Execute with guaranteed cleanup
    let driver = SolarmanDriver(client: client, logger: logger, metrics: metrics)

    // Closure to safely close connection (ignores close errors to preserve original)
    @Sendable
    func closeConnection() async {
        await client.close()
    }

    do {
        let result = try await operation(driver, profile)
        await closeConnection()
        return result
    } catch {
        await closeConnection()
        throw error
    }
}

/// Executes an operation with a connected Solarman driver (simplified).
///
/// Simplified version that reads specified groups directly.
///
/// **Example:**
/// ```swift
/// let status = try await withSolarmanDriver(
///     host: "192.168.1.100",
///     serial: 2712345678,
///     profile: .deyeP3,
///     groups: [.battery, .pv, .grid]
/// )
/// print("SOC: \(status.battery?.soc ?? 0)%")
/// ```
///
/// - Parameters:
///   - host: Hostname or IP address of the data logging stick
///   - serial: Serial number of the data logging stick (10 digits)
///   - profile: Profile ID to load
///   - groups: Sensor groups to read (default: basic groups)
///   - port: TCP port (default: 8899)
///   - unitId: Modbus unit ID (default: 1)
///   - timeout: Connection and read timeout (default: 60 seconds)
///   - logger: Optional logger for debugging
///   - metrics: Optional metrics for observability
/// - Returns: Solar status with requested data
/// - Throws: `DriverError` on connection, profile, or read failure
public func withSolarmanDriver(
    host: String,
    serial: UInt32,
    profile profileId: ProfileID,
    groups: Set<SensorGroup> = SensorGroup.basic,
    port: Int = 8899,
    unitId: UInt8 = 1,
    timeout: Duration = .seconds(60),
    logger: Logger? = nil,
    metrics: DriverMetrics? = nil,
) async throws(DriverError) -> SolarStatus {
    let capturedGroups = groups
    return try await withSolarmanDriver(
        host: host,
        serial: serial,
        profile: profileId,
        port: port,
        unitId: unitId,
        timeout: timeout,
        logger: logger,
        metrics: metrics,
    ) {
        (driver: SolarmanDriver, profile: InverterDefinition) async throws(DriverError) -> SolarStatus
        in
        try await driver.read(profile: profile, groups: capturedGroups)
    }
}
