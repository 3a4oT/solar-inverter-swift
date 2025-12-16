// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

@testable import SolarCore
import Testing

/// Tests for RegisterBatcher optimizing Modbus read operations.
///
/// Test scenarios based on real inverter register layouts:
/// - Deye hybrid: Multiple register ranges (battery, PV, grid, load)
/// - Modbus protocol: Max 125 registers per request
@Suite("RegisterBatcher")
struct RegisterBatcherTests {
    // MARK: - Basic Batching

    @Suite("Basic Batching")
    struct BasicTests {
        @Test("Empty addresses returns empty ranges")
        func emptyAddresses() {
            let batcher = RegisterBatcher()
            let ranges = batcher.batch(addresses: [])
            #expect(ranges.isEmpty)
        }

        @Test("Single address returns single range")
        func singleAddress() {
            let batcher = RegisterBatcher()
            let ranges = batcher.batch(addresses: [100])

            #expect(ranges.count == 1)
            #expect(ranges[0].startAddress == 100)
            #expect(ranges[0].count == 1)
        }

        @Test("Contiguous addresses batch together")
        func contiguousAddresses() {
            let batcher = RegisterBatcher()
            // Registers 100, 101, 102
            let ranges = batcher.batch(addresses: [100, 101, 102])

            #expect(ranges.count == 1)
            #expect(ranges[0].startAddress == 100)
            #expect(ranges[0].count == 3)
        }

        @Test("Duplicate addresses deduplicated")
        func duplicateAddresses() {
            let batcher = RegisterBatcher()
            let ranges = batcher.batch(addresses: [100, 100, 101, 101, 102])

            #expect(ranges.count == 1)
            #expect(ranges[0].startAddress == 100)
            #expect(ranges[0].count == 3)
        }

        @Test("Unsorted addresses sorted before batching")
        func unsortedAddresses() {
            let batcher = RegisterBatcher()
            let ranges = batcher.batch(addresses: [102, 100, 101])

            #expect(ranges.count == 1)
            #expect(ranges[0].startAddress == 100)
            #expect(ranges[0].count == 3)
        }
    }

    // MARK: - Gap Handling

    @Suite("Gap Handling")
    struct GapTests {
        @Test("Small gap batched together - default maxGap 10")
        func smallGapBatched() {
            let batcher = RegisterBatcher() // maxGap = 10
            // Gap of 5 between 100-102 and 108-110
            let ranges = batcher.batch(addresses: [100, 101, 102, 108, 109, 110])

            #expect(ranges.count == 1)
            #expect(ranges[0].startAddress == 100)
            #expect(ranges[0].count == 11) // 100-110 inclusive
        }

        @Test("Large gap creates separate ranges")
        func largeGapSeparate() {
            let batcher = RegisterBatcher() // maxGap = 10
            // Gap of 20 between 100-102 and 123-125
            let ranges = batcher.batch(addresses: [100, 101, 102, 123, 124, 125])

            #expect(ranges.count == 2)
            #expect(ranges[0].startAddress == 100)
            #expect(ranges[0].count == 3)
            #expect(ranges[1].startAddress == 123)
            #expect(ranges[1].count == 3)
        }

        @Test("Custom maxGap respected")
        func customMaxGap() {
            let batcher = RegisterBatcher(maxGap: 5)
            // Gap of 8 - should create separate ranges with maxGap=5
            let ranges = batcher.batch(addresses: [100, 101, 110, 111])

            #expect(ranges.count == 2)
        }

        @Test("Gap exactly at maxGap batched together")
        func gapAtMaxGap() {
            let batcher = RegisterBatcher(maxGap: 10)
            // Gap of exactly 10: 100, 111 (gap = 10)
            let ranges = batcher.batch(addresses: [100, 111])

            #expect(ranges.count == 1)
            #expect(ranges[0].startAddress == 100)
            #expect(ranges[0].count == 12) // 100-111 inclusive
        }

        @Test("Gap one over maxGap creates separate ranges")
        func gapOverMaxGap() {
            let batcher = RegisterBatcher(maxGap: 10)
            // Gap of 11: 100, 112
            let ranges = batcher.batch(addresses: [100, 112])

            #expect(ranges.count == 2)
        }
    }

    // MARK: - Modbus Limits

    @Suite("Modbus Protocol Limits")
    struct LimitsTests {
        @Test("Max 125 registers per request enforced")
        func maxRegistersEnforced() {
            let batcher = RegisterBatcher()
            // 200 contiguous registers should split
            let addresses = (0..<200).map { UInt16($0) }
            let ranges = batcher.batch(addresses: Array(addresses))

            #expect(ranges.count == 2)
            #expect(ranges[0].count == 125)
            #expect(ranges[1].count == 75)
        }

        @Test("Custom maxRegistersPerRequest respected")
        func customMaxRegisters() {
            let batcher = RegisterBatcher(maxRegistersPerRequest: 50)
            let addresses = (0..<100).map { UInt16($0) }
            let ranges = batcher.batch(addresses: Array(addresses))

            #expect(ranges.count == 2)
            #expect(ranges[0].count == 50)
            #expect(ranges[1].count == 50)
        }

        @Test("maxRegistersPerRequest capped at 125")
        func maxRegistersCapped() {
            let batcher = RegisterBatcher(maxRegistersPerRequest: 200)
            // Should be capped at 125
            #expect(batcher.maxRegistersPerRequest == 125)
        }

        @Test("Exact 125 registers in single range")
        func exact125Registers() {
            let batcher = RegisterBatcher()
            let addresses = (0..<125).map { UInt16($0) }
            let ranges = batcher.batch(addresses: Array(addresses))

            #expect(ranges.count == 1)
            #expect(ranges[0].count == 125)
        }
    }

    // MARK: - Real World Scenarios

    @Suite("Real Inverter Scenarios")
    struct RealWorldTests {
        @Test("Deye hybrid typical register layout")
        func deyeHybridLayout() {
            let batcher = RegisterBatcher()

            // Typical Deye register groups:
            // - Battery: 0x00B0-0x00C0 (176-192)
            // - PV: 0x006D-0x0078 (109-120)
            // - Grid: 0x00A0-0x00B0 (160-176)
            // - Load: 0x0054-0x0060 (84-96)

            let addresses: [UInt16] = [
                // Load group
                84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96,
                // PV group
                109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120,
                // Grid group
                160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176,
                // Battery group
                176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192,
            ]

            let ranges = batcher.batch(addresses: addresses)

            // With default maxGap=10:
            // - Load (84-96) and PV (109-120) have gap of 12 -> separate
            // - PV (109-120) and Grid (160-176) have gap of 39 -> separate
            // - Grid and Battery overlap at 176 -> should merge

            // Expect 3 ranges: Load, PV, Grid+Battery
            #expect(ranges.count == 3)
            #expect(ranges[0].startAddress == 84)
            #expect(ranges[1].startAddress == 109)
            #expect(ranges[2].startAddress == 160)
        }

        @Test("Energy counters - 32-bit registers")
        func energyCounters() {
            let batcher = RegisterBatcher()

            // 32-bit energy counters need 2 consecutive registers each
            // Total production: 0x0060-0x0061
            // Total consumption: 0x0055-0x0056
            // Daily production: 0x006C-0x006D

            let addresses: [UInt16] = [
                0x55, 0x56, // Total consumption
                0x60, 0x61, // Total production
                0x6C, 0x6D, // Daily production
            ]

            let ranges = batcher.batch(addresses: addresses)

            // Gap between 0x56 and 0x60 is 9 - within default maxGap
            // Gap between 0x61 and 0x6C is 10 - within default maxGap
            // Should all batch together
            #expect(ranges.count == 1)
            #expect(ranges[0].startAddress == 0x55)
            #expect(ranges[0].endAddress == 0x6D)
        }

        @Test("Sparse status flags - separate reads efficient")
        func sparseStatusFlags() {
            let batcher = RegisterBatcher(maxGap: 3) // Smaller gap for status flags

            // Status flags scattered across register space
            let addresses: [UInt16] = [
                0x0000, // System status
                0x0010, // Fault flags
                0x0020, // Warning flags
                0x0030, // Mode flags
            ]

            let ranges = batcher.batch(addresses: addresses)

            // With maxGap=3, each should be separate
            #expect(ranges.count == 4)
        }

        @Test("Single string PV system")
        func singleStringPV() {
            let batcher = RegisterBatcher()

            // Simple single-string PV: voltage, current, power
            let addresses: [UInt16] = [109, 110, 186]

            let ranges = batcher.batch(addresses: addresses)

            // 109-110 contiguous, 186 is far away (gap 75)
            #expect(ranges.count == 2)
            #expect(ranges[0].startAddress == 109)
            #expect(ranges[0].count == 2)
            #expect(ranges[1].startAddress == 186)
            #expect(ranges[1].count == 1)
        }
    }

    // MARK: - Sensor Item Batching

    @Suite("Sensor Item Batching")
    struct SensorItemBatchingTests {
        @Test("Batch from sensor items")
        func batchFromItems() {
            let batcher = RegisterBatcher()

            let items = [
                SensorItem(name: "PV1 Voltage", registers: [109], rule: .uint16),
                SensorItem(name: "PV1 Current", registers: [110], rule: .uint16),
                SensorItem(name: "PV1 Power", registers: [186], rule: .uint16),
            ]

            let ranges = batcher.batch(items: items)

            #expect(ranges.count == 2) // 109-110 and 186
        }

        @Test("32-bit sensor uses both registers")
        func sensor32BitRegisters() {
            let batcher = RegisterBatcher()

            let items = [
                SensorItem(
                    name: "Total Energy",
                    registers: [0x60, 0x61],
                    rule: .uint32,
                    scale: 0.1,
                ),
            ]

            let ranges = batcher.batch(items: items)

            #expect(ranges.count == 1)
            #expect(ranges[0].startAddress == 0x60)
            #expect(ranges[0].count == 2)
        }
    }

    // MARK: - RegisterRange Tests

    @Suite("RegisterRange")
    struct RegisterRangeTests {
        @Test("endAddress calculated correctly")
        func endAddress() {
            let range = RegisterRange(startAddress: 100, count: 10)
            #expect(range.endAddress == 109)
        }

        @Test("contains address in range")
        func containsInRange() {
            let range = RegisterRange(startAddress: 100, count: 10)

            #expect(range.contains(100) == true)
            #expect(range.contains(105) == true)
            #expect(range.contains(109) == true)
        }

        @Test("does not contain address outside range")
        func doesNotContainOutside() {
            let range = RegisterRange(startAddress: 100, count: 10)

            #expect(range.contains(99) == false)
            #expect(range.contains(110) == false)
        }

        @Test("offset calculation")
        func offsetCalculation() {
            let range = RegisterRange(startAddress: 100, count: 10)

            #expect(range.offset(of: 100) == 0)
            #expect(range.offset(of: 105) == 5)
            #expect(range.offset(of: 109) == 9)
            #expect(range.offset(of: 99) == nil)
            #expect(range.offset(of: 110) == nil)
        }

        @Test("single register range")
        func singleRegister() {
            let range = RegisterRange(startAddress: 100, count: 1)

            #expect(range.endAddress == 100)
            #expect(range.contains(100) == true)
            #expect(range.contains(99) == false)
            #expect(range.contains(101) == false)
        }
    }

    // MARK: - Edge Cases

    @Suite("Edge Cases")
    struct EdgeCaseTests {
        @Test("Address at UInt16 max")
        func maxAddress() {
            let batcher = RegisterBatcher()
            let ranges = batcher.batch(addresses: [65534, 65535])

            #expect(ranges.count == 1)
            #expect(ranges[0].startAddress == 65534)
            #expect(ranges[0].count == 2)
        }

        @Test("Address at UInt16 min")
        func minAddress() {
            let batcher = RegisterBatcher()
            let ranges = batcher.batch(addresses: [0, 1, 2])

            #expect(ranges.count == 1)
            #expect(ranges[0].startAddress == 0)
            #expect(ranges[0].count == 3)
        }

        @Test("Wide address range respects maxRegisters")
        func wideAddressRange() {
            let batcher = RegisterBatcher()
            // Addresses span more than 125 but with gaps
            let addresses: [UInt16] = [0, 130]

            let ranges = batcher.batch(addresses: addresses)

            // Gap of 129 is too large, should be separate
            #expect(ranges.count == 2)
        }

        @Test("All same address")
        func allSameAddress() {
            let batcher = RegisterBatcher()
            let ranges = batcher.batch(addresses: [100, 100, 100, 100])

            #expect(ranges.count == 1)
            #expect(ranges[0].count == 1)
        }
    }

    // MARK: - Boundary Conditions

    @Suite("Boundary Conditions")
    struct BoundaryConditionTests {
        @Test("endAddress uses wrapping arithmetic")
        func endAddressWrapping() {
            // Test that endAddress doesn't overflow when startAddress is high
            let range = RegisterRange(startAddress: 65530, count: 5)
            // 65530 + 4 = 65534 (should not overflow)
            #expect(range.endAddress == 65534)
        }

        @Test("maxGap zero forces all separate")
        func maxGapZero() {
            let batcher = RegisterBatcher(maxGap: 0)
            // Only truly contiguous registers should batch
            let ranges = batcher.batch(addresses: [100, 101, 103, 104])

            // 100-101 contiguous, 103-104 contiguous, but gap of 1 between them
            // With maxGap=0, gap > 0 should separate
            #expect(ranges.count == 2)
            #expect(ranges[0].startAddress == 100)
            #expect(ranges[0].count == 2)
            #expect(ranges[1].startAddress == 103)
            #expect(ranges[1].count == 2)
        }

        @Test("Sparse full range - extreme addresses")
        func sparseFullRange() {
            let batcher = RegisterBatcher()
            // Addresses at extremes of UInt16 range
            let addresses: [UInt16] = [0, 32768, 65535]

            let ranges = batcher.batch(addresses: addresses)

            // All should be separate due to large gaps
            #expect(ranges.count == 3)
            #expect(ranges[0].startAddress == 0)
            #expect(ranges[0].count == 1)
            #expect(ranges[1].startAddress == 32768)
            #expect(ranges[1].count == 1)
            #expect(ranges[2].startAddress == 65535)
            #expect(ranges[2].count == 1)
        }

        @Test("RegisterRange count clamped to 1 minimum")
        func rangeCountMinimum() {
            let range = RegisterRange(startAddress: 100, count: 0)
            // Count should be clamped to at least 1
            #expect(range.count == 1)
        }

        @Test("RegisterRange count clamped to 125 maximum")
        func rangeCountMaximum() {
            let range = RegisterRange(startAddress: 100, count: 200)
            // Count should be clamped to 125
            #expect(range.count == 125)
        }

        @Test("endAddress with count zero returns startAddress")
        func endAddressZeroCount() {
            // Edge case: if somehow count is 0, endAddress should be safe
            let range = RegisterRange(startAddress: 100, count: 0)
            // Note: count is clamped to 1, so endAddress = 100
            #expect(range.endAddress == 100)
        }

        @Test("Very large contiguous range splits correctly")
        func veryLargeContiguousRange() {
            let batcher = RegisterBatcher()
            // 500 contiguous registers
            let addresses = (0..<500).map { UInt16($0) }
            let ranges = batcher.batch(addresses: Array(addresses))

            // Should split into: 125 + 125 + 125 + 125 = 500
            #expect(ranges.count == 4)
            #expect(ranges[0].count == 125)
            #expect(ranges[1].count == 125)
            #expect(ranges[2].count == 125)
            #expect(ranges[3].count == 125)
        }

        @Test("High address near max with gap")
        func highAddressWithGap() {
            let batcher = RegisterBatcher()
            // Near UInt16 max with a gap
            let addresses: [UInt16] = [65400, 65401, 65500, 65501]

            let ranges = batcher.batch(addresses: addresses)

            // Gap of 98 between 65401 and 65500, larger than maxGap=10
            #expect(ranges.count == 2)
            #expect(ranges[0].startAddress == 65400)
            #expect(ranges[0].count == 2)
            #expect(ranges[1].startAddress == 65500)
            #expect(ranges[1].count == 2)
        }
    }
}
