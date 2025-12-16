// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - SolarDriver

/// Protocol for reading solar system data from inverters.
///
/// Drivers orchestrate the reading process:
/// 1. Batch register addresses from profile
/// 2. Read via transport (Solarman V5, Modbus TCP)
/// 3. Convert raw registers to typed values
/// 4. Build `SolarStatus` output
///
/// ## Usage
///
/// ```swift
/// let driver: any SolarDriver = SolarmanDriver(client: client)
/// let profile = try profileLoader.load(.deyeHybridSinglePhase)
///
/// let status = try await driver.read(
///     profile: profile,
///     groups: [.battery, .pv, .grid]
/// )
///
/// if let battery = status.battery {
///     print("SOC: \(battery.soc)%")
/// }
/// ```
public protocol SolarDriver: Sendable {
    /// Read sensor data from the inverter.
    ///
    /// - Parameters:
    ///   - profile: Inverter definition (ha-solarman format).
    ///   - groups: Sensor groups to read. Empty uses basic groups.
    /// - Returns: Status snapshot with requested data.
    func read(
        profile: InverterDefinition,
        groups: Set<SensorGroup>,
    ) async throws(DriverError) -> SolarStatus
}

// MARK: - Convenience Methods

extension SolarDriver {
    /// Read basic sensor groups (battery, grid, pv, load).
    public func readBasic(
        profile: InverterDefinition,
    ) async throws(DriverError) -> SolarStatus {
        try await read(profile: profile, groups: SensorGroup.basic)
    }

    /// Read all status sensor groups.
    public func readAll(
        profile: InverterDefinition,
    ) async throws(DriverError) -> SolarStatus {
        try await read(profile: profile, groups: SensorGroup.allStatus)
    }
}
