// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - DeviceInfo

/// Device identification information from inverter.
///
/// Used for automatic profile matching and device discovery.
/// Most Modbus-compatible inverters provide this information
/// in standard holding registers (typically 0x00-0x30).
///
/// ## Example
///
/// ```swift
/// let device = try await driver.identify()
/// // DeviceInfo(manufacturer: "DEYE", model: "SUN-12K-SG01HP3-EU", ...)
///
/// switch ProfileRegistry.find(for: device) {
/// case .found(let profile):
///     let status = try await driver.read(profile: profile)
/// case .unsupported(let suggestion):
///     print("Device not supported. Try: \(suggestion?.name ?? "unknown")")
/// case .unknown:
///     print("Unknown device: \(device.manufacturer) \(device.model)")
/// }
/// ```
public struct DeviceInfo: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    /// Creates device information.
    ///
    /// - Parameters:
    ///   - manufacturer: Manufacturer name.
    ///   - model: Model identifier.
    ///   - serial: Device serial number.
    ///   - firmwareVersion: Firmware version string.
    ///   - protocolVersion: Protocol version string.
    ///   - ratedPower: Rated power in Watts.
    ///   - modbusAddress: Modbus slave address.
    ///   - mpptCount: Number of MPPT inputs.
    ///   - phaseCount: Number of AC phases.
    ///   - chipType: Microcontroller chip type.
    public init(
        manufacturer: String,
        model: String,
        serial: String,
        firmwareVersion: String? = nil,
        protocolVersion: String? = nil,
        ratedPower: Int? = nil,
        modbusAddress: Int? = nil,
        mpptCount: Int? = nil,
        phaseCount: Int? = nil,
        chipType: String? = nil,
    ) {
        self.manufacturer = manufacturer
        self.model = model
        self.serial = serial
        self.firmwareVersion = firmwareVersion
        self.protocolVersion = protocolVersion
        self.ratedPower = ratedPower
        self.modbusAddress = modbusAddress
        self.mpptCount = mpptCount
        self.phaseCount = phaseCount
        self.chipType = chipType
    }

    // MARK: Public

    /// Manufacturer name (e.g., "DEYE", "VICTRON", "SOLIS").
    public let manufacturer: String

    /// Model identifier (e.g., "SUN-12K-SG01HP3-EU").
    public let model: String

    /// Device serial number.
    public let serial: String

    /// Firmware version (if available).
    public let firmwareVersion: String?

    /// Protocol version supported by device.
    public let protocolVersion: String?

    /// Rated power in Watts (if available).
    public let ratedPower: Int?

    /// Modbus slave address (typically 1).
    public let modbusAddress: Int?

    /// Number of MPPT (Maximum Power Point Tracking) inputs.
    ///
    /// Typical values: 1-4 for residential, up to 12 for commercial.
    public let mpptCount: Int?

    /// Number of AC phases (1 or 3).
    public let phaseCount: Int?

    /// Microcontroller chip type (e.g., "AT32F403A", "GD32F303").
    public let chipType: String?
}

// MARK: DeviceInfo.Manufacturer

extension DeviceInfo {
    /// Known manufacturer identifiers.
    public enum Manufacturer {
        public static let deye = "DEYE"
        public static let victron = "VICTRON"
        public static let solis = "SOLIS"
        public static let growatt = "GROWATT"
        public static let sofar = "SOFAR"
        public static let sunsynk = "SUNSYNK"
        public static let unknown = "UNKNOWN"
    }
}

// MARK: CustomStringConvertible

extension DeviceInfo: CustomStringConvertible {
    public var description: String {
        var parts = ["\(manufacturer) \(model)"]
        if let firmware = firmwareVersion {
            parts.append("FW: \(firmware)")
        }
        parts.append("S/N: \(serial)")
        return parts.joined(separator: " | ")
    }
}
