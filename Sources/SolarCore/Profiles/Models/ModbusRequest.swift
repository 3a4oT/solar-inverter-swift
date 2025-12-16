// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - ModbusRequest

/// Optimized Modbus read request definition.
///
/// Profiles define pre-computed request ranges for efficient reading.
/// This avoids runtime batching calculation for known profiles.
///
/// ## Example YAML
///
/// ```yaml
/// requests:
///   - start: 0x0003
///     count: 109
///     function: holding
///   - start: 0x0096
///     count: 99
///     function: holding
/// ```
public struct ModbusRequest: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    public init(
        start: UInt16,
        count: UInt16,
        function: ModbusFunction = .holdingRegisters,
        name: String? = nil,
    ) {
        self.start = start
        self.count = count
        self.function = function
        self.name = name
    }

    // MARK: Public

    /// Starting register address.
    public let start: UInt16

    /// Number of registers to read.
    public let count: UInt16

    /// Modbus function code type.
    public let function: ModbusFunction

    /// Optional request name for debugging.
    public let name: String?
}

// MARK: - ModbusFunction

/// Modbus function codes for register reading.
public enum ModbusFunction: String, Sendable, Codable, Equatable {
    /// Function code 0x03 - Read Holding Registers.
    case holdingRegisters = "holding"

    /// Function code 0x04 - Read Input Registers.
    case inputRegisters = "input"

    // MARK: Public

    /// Modbus function code value.
    public var code: UInt8 {
        switch self {
        case .holdingRegisters: 0x03
        case .inputRegisters: 0x04
        }
    }
}

// MARK: - Convenience

extension ModbusRequest {
    /// Ending address (inclusive).
    public var endAddress: UInt16 {
        start + count - 1
    }

    /// Check if address is within this request range.
    public func contains(_ address: UInt16) -> Bool {
        address >= start && address <= endAddress
    }

    /// Get offset of address within this request.
    public func offset(of address: UInt16) -> Int? {
        guard contains(address) else {
            return nil
        }
        return Int(address - start)
    }
}
