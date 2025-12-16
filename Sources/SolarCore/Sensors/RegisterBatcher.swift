// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - RegisterBatcher

/// Optimizes register reads by batching contiguous address ranges.
///
/// Modbus has a limit of 125 registers per request. This batcher groups
/// sensor addresses into efficient read ranges while respecting limits.
///
/// ## Security
/// - Enforces maximum registers per request (default: 125)
/// - Validates all inputs are within valid range (0-65535)
/// - No unbounded allocations
///
/// ## Example
///
/// ```swift
/// let batcher = RegisterBatcher()
///
/// // Sensors at addresses: 100, 101, 102, 200, 201, 500
/// let ranges = batcher.batch(addresses: [100, 101, 102, 200, 201, 500])
/// // Result: [(100, 3), (200, 2), (500, 1)]
///
/// // With custom gap threshold (registers 200-201 would join 100-102)
/// let ranges = batcher.batch(addresses: [100, 101, 102, 200, 201], maxGap: 100)
/// // Result: [(100, 102)]  // One range from 100-201
/// ```
public struct RegisterBatcher: Sendable {
    // MARK: Lifecycle

    public init(
        maxRegistersPerRequest: Int = modbusMaxRegisters,
        maxGap: Int = defaultMaxGap,
    ) {
        self.maxRegistersPerRequest = min(maxRegistersPerRequest, Self.modbusMaxRegisters)
        self.maxGap = maxGap
    }

    // MARK: Public

    /// Maximum registers per Modbus read request.
    /// Per Modbus spec, function codes 0x03/0x04 allow max 125 registers.
    public static let modbusMaxRegisters = 125

    /// Default maximum gap between addresses before starting new range.
    /// Reading a few extra registers is cheaper than a new request.
    public static let defaultMaxGap = 10

    /// Maximum registers to request in one read.
    public let maxRegistersPerRequest: Int

    /// Maximum gap between addresses to still batch together.
    public let maxGap: Int

    /// Batch addresses into efficient read ranges.
    ///
    /// - Parameter addresses: Register addresses to read.
    /// - Returns: Array of (startAddress, count) tuples for batch reads.
    public func batch(addresses: [UInt16]) -> [RegisterRange] {
        guard !addresses.isEmpty else {
            return []
        }

        // Sort and deduplicate
        let sorted = Array(Set(addresses)).sorted()

        var ranges: [RegisterRange] = []
        var rangeStart = sorted[0]
        var rangeEnd = sorted[0]

        for i in 1..<sorted.count {
            let address = sorted[i]
            let gap = Int(address) - Int(rangeEnd)

            // Check if this address can be added to current range
            let newRangeSize = Int(address) - Int(rangeStart) + 1

            if gap <= maxGap + 1, newRangeSize <= maxRegistersPerRequest {
                // Extend current range
                rangeEnd = address
            } else {
                // Save current range and start new one
                let count = Int(rangeEnd) - Int(rangeStart) + 1
                ranges.append(RegisterRange(startAddress: rangeStart, count: count))
                rangeStart = address
                rangeEnd = address
            }
        }

        // Don't forget the last range
        let count = Int(rangeEnd) - Int(rangeStart) + 1
        ranges.append(RegisterRange(startAddress: rangeStart, count: count))

        return ranges
    }

    /// Batch sensor items into efficient read ranges.
    ///
    /// - Parameter items: Sensor items to batch.
    /// - Returns: Array of register ranges for batch reads.
    public func batch(items: [SensorItem]) -> [RegisterRange] {
        let addresses = items.flatMap(\.registers)
        return batch(addresses: addresses)
    }
}

// MARK: - RegisterRange

/// A contiguous range of registers to read in one Modbus request.
public struct RegisterRange: Sendable, Equatable {
    // MARK: Lifecycle

    /// Creates a register range with validation.
    ///
    /// - Parameters:
    ///   - startAddress: Starting register address.
    ///   - count: Number of registers (clamped to 1...125).
    public init(startAddress: UInt16, count: Int) {
        self.startAddress = startAddress
        // Clamp to valid Modbus range to prevent overflow
        self.count = max(1, min(count, RegisterBatcher.modbusMaxRegisters))
    }

    // MARK: Public

    /// Starting register address.
    public let startAddress: UInt16

    /// Number of registers to read (1-125, per Modbus spec).
    public let count: Int

    /// Ending register address (inclusive).
    ///
    /// Returns `startAddress` if `count <= 0` to avoid overflow.
    public var endAddress: UInt16 {
        guard count > 0 else {
            return startAddress
        }
        // Safe: count is clamped to 125 max, and batch() ensures no overflow
        return startAddress &+ UInt16(count - 1)
    }

    /// Check if an address is within this range.
    public func contains(_ address: UInt16) -> Bool {
        address >= startAddress && address <= endAddress
    }

    /// Get offset of address within this range.
    ///
    /// - Parameter address: Address to find.
    /// - Returns: Offset from start, or nil if not in range.
    public func offset(of address: UInt16) -> Int? {
        guard contains(address) else {
            return nil
        }
        return Int(address - startAddress)
    }
}
