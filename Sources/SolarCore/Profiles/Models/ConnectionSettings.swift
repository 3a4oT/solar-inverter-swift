// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - ConnectionSettings

/// Connection settings for inverter communication.
///
/// Defines protocol-specific defaults and constraints.
///
/// ## Example YAML
///
/// ```yaml
/// connection:
///   protocol: solarman_v5
///   default_port: 8899
///   unit_id: 1
///   timeout_ms: 5000
///   retry_count: 3
/// ```
public struct ConnectionSettings: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    public init(
        protocol: CommunicationProtocol = .solarmanV5,
        defaultPort: UInt16 = 8899,
        unitId: UInt8 = 1,
        timeoutMs: UInt32 = 5000,
        retryCount: UInt8 = 3,
        requestDelayMs: UInt32 = 0,
    ) {
        self.protocol = `protocol`
        self.defaultPort = defaultPort
        self.unitId = unitId
        self.timeoutMs = timeoutMs
        self.retryCount = retryCount
        self.requestDelayMs = requestDelayMs
    }

    // MARK: Public

    /// Communication protocol.
    public let `protocol`: CommunicationProtocol

    /// Default port number.
    public let defaultPort: UInt16

    /// Modbus unit/slave ID.
    public let unitId: UInt8

    /// Request timeout in milliseconds.
    public let timeoutMs: UInt32

    /// Number of retries on failure.
    public let retryCount: UInt8

    /// Inter-request delay in milliseconds (some inverters need this).
    public let requestDelayMs: UInt32
}

// MARK: - CommunicationProtocol

/// Supported communication protocols.
public enum CommunicationProtocol: String, Sendable, Codable, Equatable {
    /// Solarman V5 protocol (WiFi stick).
    case solarmanV5 = "solarman_v5"

    /// Standard Modbus TCP.
    case modbusTCP = "modbus_tcp"

    /// Modbus RTU over TCP.
    case modbusRTUoverTCP = "modbus_rtu_tcp"

    /// Modbus RTU over Serial.
    case modbusRTU = "modbus_rtu"
}

// MARK: - ConnectionSettings.CodingKeys

extension ConnectionSettings {
    enum CodingKeys: String, CodingKey {
        case `protocol`
        case defaultPort = "default_port"
        case unitId = "unit_id"
        case timeoutMs = "timeout_ms"
        case retryCount = "retry_count"
        case requestDelayMs = "request_delay_ms"
    }
}
