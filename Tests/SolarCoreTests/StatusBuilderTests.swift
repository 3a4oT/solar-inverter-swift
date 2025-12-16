// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

@testable import SolarCore
import Testing

// MARK: - StatusBuilderTests

/// Tests for StatusBuilder full build pipeline.
///
/// Component-specific tests are in separate files:
/// - StatusBuilder+BatteryTests.swift
/// - StatusBuilder+GridTests.swift
/// - StatusBuilder+PVTests.swift
/// - StatusBuilder+LoadTests.swift
/// - StatusBuilder+InverterTests.swift
/// - StatusBuilder+UPSTests.swift
/// - StatusBuilder+GeneratorTests.swift
/// - StatusBuilder+BMSTests.swift
@Suite("StatusBuilder")
struct StatusBuilderTests {
    let builder = StatusBuilder()

    // MARK: - Full Build Tests

    @Test("Builds full status from profile and registers")
    func buildFullStatus() throws {
        // Create minimal profile with Battery group
        let profile = makeTestProfile(
            groups: [
                ParameterGroup(
                    group: "Battery",
                    items: [
                        SensorItem(
                            name: "Battery SOC",
                            registers: [184],
                            rule: .uint16,
                        ),
                        SensorItem(
                            name: "Battery Voltage",
                            registers: [183],
                            rule: .uint16,
                            scale: 0.01,
                        ),
                        SensorItem(
                            name: "Battery Power",
                            registers: [190],
                            rule: .int16,
                        ),
                    ],
                ),
            ],
        )

        let registers: [UInt16: UInt16] = [
            184: 85,
            183: 5120, // 51.2V with scale 0.01
            190: UInt16(bitPattern: -1500),
        ]

        let status = try builder.build(
            from: registers,
            profile: profile,
            groups: [.battery],
        )

        let battery = status.battery
        #expect(battery?.soc == 85)
        #expect(battery?.voltage == 51.2)
        #expect(battery?.power == -1500)
    }

    @Test("Excludes non-requested groups")
    func excludeNonRequestedGroups() throws {
        let profile = makeTestProfile(
            groups: [
                ParameterGroup(
                    group: "Battery",
                    items: [
                        SensorItem(name: "Battery SOC", registers: [184], rule: .uint16),
                        SensorItem(name: "Battery Voltage", registers: [183], rule: .uint16, scale: 0.01),
                        SensorItem(name: "Battery Power", registers: [190], rule: .int16),
                    ],
                ),
                ParameterGroup(
                    group: "PV",
                    items: [
                        SensorItem(name: "PV1 Power", registers: [186], rule: .uint16),
                    ],
                ),
            ],
        )

        let registers: [UInt16: UInt16] = [
            184: 80,
            183: 5000,
            190: 500,
            186: 3000,
        ]

        // Only request battery
        let status = try builder.build(
            from: registers,
            profile: profile,
            groups: [.battery],
        )

        #expect(status.battery != nil)
        #expect(status.pv == nil) // Not requested
    }

    @Test("Returns nil for groups without data")
    func nilForMissingData() throws {
        let profile = makeTestProfile(
            groups: [
                ParameterGroup(
                    group: "Battery",
                    items: [
                        SensorItem(name: "Battery SOC", registers: [184], rule: .uint16),
                        SensorItem(name: "Battery Voltage", registers: [183], rule: .uint16),
                        SensorItem(name: "Battery Power", registers: [190], rule: .int16),
                    ],
                ),
            ],
        )

        // Empty registers - no data
        let registers: [UInt16: UInt16] = [:]

        let status = try builder.build(
            from: registers,
            profile: profile,
            groups: [.battery, .grid, .pv],
        )

        #expect(status.battery == nil)
        #expect(status.grid == nil)
        #expect(status.pv == nil)
    }
}

// MARK: - Test Helpers

private func makeTestProfile(
    groups: [ParameterGroup],
) -> InverterDefinition {
    InverterDefinition(
        info: ProfileInfo(
            manufacturer: "Test",
            model: "TEST-001",
        ),
        default: nil,
        parameters: groups,
    )
}
