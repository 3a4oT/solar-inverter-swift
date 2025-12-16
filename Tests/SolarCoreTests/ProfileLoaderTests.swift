// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

@testable import SolarCore
import Testing

/// Tests for ProfileLoader YAML parsing (ha-solarman format).
@Suite("ProfileLoader")
struct ProfileLoaderTests {
    // MARK: - Type-Safe Loading (ProfileID)

    @Suite("ProfileID Loading")
    struct ProfileIDTests {
        let loader = ProfileLoader()

        @Test("ProfileID properties are correct")
        func profileIDProperties() {
            #expect(ProfileID.deyeHybridSinglePhase.id == "deye_hybrid")
            #expect(ProfileID.deyeHybridSinglePhase.manufacturer == "deye")
            #expect(ProfileID.deyeHybridSinglePhase.displayName == "Deye Hybrid (1P)")
            #expect(ProfileID.deyeHybridThreePhase.id == "deye_p3")
            #expect(ProfileID.deyeHybridThreePhase.displayName == "Deye Hybrid (3P)")
        }

        @Test("ProfileID allCases contains all profiles")
        func allCases() {
            #expect(ProfileID.allCases.count >= 4)
            #expect(ProfileID.allCases.contains(.deyeHybridSinglePhase))
            #expect(ProfileID.allCases.contains(.deyeHybridThreePhase))
        }

        @Test("ProfileID manufacturers grouping")
        func manufacturersGrouping() {
            let deyeProfiles = ProfileID.profiles(for: "deye")
            #expect(deyeProfiles.contains(.deyeHybridSinglePhase))
            #expect(deyeProfiles.contains(.deyeHybridThreePhase))

            let manufacturers = ProfileID.manufacturers
            #expect(manufacturers.contains("deye"))
        }
    }

    // MARK: - YAML Parsing

    @Suite("YAML Parsing")
    struct ParsingTests {
        let loader = ProfileLoader()

        @Test("Parse minimal upstream format")
        func parseMinimalFormat() throws {
            let yaml = """
            info:
              manufacturer: TEST
              model: TEST-001

            parameters:
              - group: Battery
                items:
                  - name: "Battery SOC"
                    rule: 1
                    registers: [184]
                    uom: "%"
            """

            let profile = try loader.parse(yaml: yaml, profileId: "test")

            #expect(profile.manufacturer == "TEST")
            #expect(profile.model == "TEST-001")
            #expect(profile.parameters.count == 1)
            #expect(profile.parameters[0].group == "Battery")
            #expect(profile.parameters[0].items.count == 1)
            #expect(profile.parameters[0].items[0].name == "Battery SOC")
            #expect(profile.parameters[0].items[0].rule == .uint16)
        }

        @Test("Parse with default settings")
        func parseWithDefaults() throws {
            let yaml = """
            info:
              manufacturer: TEST
              model: TEST-001

            default:
              update_interval: 10
              digits: 3

            parameters: []
            """

            let profile = try loader.parse(yaml: yaml, profileId: "test")

            #expect(profile.updateInterval == 10)
            #expect(profile.digits == 3)
        }

        @Test("Parse sensor with transformation")
        func parseWithTransformation() throws {
            let yaml = """
            info:
              manufacturer: TEST
              model: TEST-001

            parameters:
              - group: Battery
                items:
                  - name: "Battery Voltage"
                    rule: 1
                    registers: [183]
                    scale: 0.01
                    offset: 0
                    uom: "V"
            """

            let profile = try loader.parse(yaml: yaml, profileId: "test")
            let item = profile.parameters[0].items[0]

            #expect(item.name == "Battery Voltage")
            #expect(item.scale == 0.01)
            #expect(item.offset == 0.0)
            #expect(item.uom == "V")
        }

        @Test("Parse sensor with lookup")
        func parseWithLookup() throws {
            let yaml = """
            info:
              manufacturer: TEST
              model: TEST-001

            parameters:
              - group: Info
                items:
                  - name: "Device State"
                    rule: 1
                    registers: [500]
                    lookup:
                      - key: 0
                        value: "Standby"
                      - key: 1
                        value: "Running"
                      - key: 2
                        value: "Fault"
            """

            let profile = try loader.parse(yaml: yaml, profileId: "test")
            let item = profile.parameters[0].items[0]

            #expect(item.lookup.count == 3)
            #expect(item.lookupValue(for: 0) == "Standby")
            #expect(item.lookupValue(for: 1) == "Running")
        }

        @Test("Parse signed int16 sensor")
        func parseSignedInt16() throws {
            let yaml = """
            info:
              manufacturer: TEST
              model: TEST-001

            parameters:
              - group: Battery
                items:
                  - name: "Battery Power"
                    rule: 2
                    registers: [190]
                    uom: "W"
            """

            let profile = try loader.parse(yaml: yaml, profileId: "test")
            let item = profile.parameters[0].items[0]

            #expect(item.rule == .int16)
        }

        @Test("Parse 32-bit sensor")
        func parse32Bit() throws {
            let yaml = """
            info:
              manufacturer: TEST
              model: TEST-001

            parameters:
              - group: Energy
                items:
                  - name: "Total Production"
                    rule: 3
                    registers: [96, 97]
                    scale: 0.1
                    uom: "kWh"
            """

            let profile = try loader.parse(yaml: yaml, profileId: "test")
            let item = profile.parameters[0].items[0]

            #expect(item.rule == .uint32)
            #expect(item.registers == [96, 97])
        }
    }

    // MARK: - Size Validation

    @Suite("Size Validation")
    struct SizeValidationTests {
        let loader = ProfileLoader()

        @Test("Rejects oversized YAML")
        func rejectsOversizedYAML() throws {
            let oversizedYAML = String(repeating: "x", count: ProfileLoader.maxYAMLSize + 1)

            #expect(throws: ProfileError.self) {
                try loader.parse(yaml: oversizedYAML, profileId: "test")
            }
        }
    }

    // MARK: - Error Handling

    @Suite("Error Handling")
    struct ErrorHandlingTests {
        let loader = ProfileLoader()

        @Test("Invalid YAML throws parse error")
        func invalidYAML() throws {
            let yaml = """
            info:
              manufacturer: [invalid
            """

            #expect(throws: ProfileError.self) {
                try loader.parse(yaml: yaml, profileId: "test")
            }
        }

        @Test("Missing required field throws error")
        func missingRequiredField() throws {
            let yaml = """
            info:
              manufacturer: TEST
              # Missing model

            parameters: []
            """

            #expect(throws: ProfileError.self) {
                try loader.parse(yaml: yaml, profileId: "test")
            }
        }

        @Test("Unknown profile ID throws error")
        func unknownProfileID() throws {
            #expect(
                throws: ProfileError.profileLoadFailed(
                    profileId: "nonexistent",
                    reason: "Profile not found in bundle",
                ),
            ) {
                try loader.load(id: "nonexistent")
            }
        }
    }

    // MARK: - Convenience Accessors

    @Suite("Convenience Accessors")
    struct AccessorTests {
        let loader = ProfileLoader()

        @Test("Profile convenience accessors work")
        func convenienceAccessors() throws {
            let yaml = """
            info:
              manufacturer: TEST
              model: TEST-001

            default:
              update_interval: 5

            parameters:
              - group: Battery
                items:
                  - name: "Battery SOC"
                    rule: 1
                    registers: [184]
              - group: PV
                items:
                  - name: "PV1 Power"
                    rule: 1
                    registers: [186]
                  - name: "PV2 Power"
                    rule: 1
                    registers: [187]
            """

            let profile = try loader.parse(yaml: yaml, profileId: "test")

            #expect(profile.manufacturer == "TEST")
            #expect(profile.model == "TEST-001")
            #expect(profile.updateInterval == 5)
            #expect(profile.allItems.count == 3)
            #expect(profile.itemCount == 3)
            #expect(profile.groupNames == ["Battery", "PV"])
        }

        @Test("Group access works")
        func groupAccess() throws {
            let yaml = """
            info:
              manufacturer: TEST
              model: TEST-001

            parameters:
              - group: Battery
                items:
                  - name: "Battery SOC"
                    rule: 1
                    registers: [184]
            """

            let profile = try loader.parse(yaml: yaml, profileId: "test")

            let batteryGroup = profile.group(named: "Battery")
            #expect(batteryGroup != nil)
            #expect(batteryGroup?.items.count == 1)

            let batteryItems = profile.items(inGroup: "battery") // Case-insensitive
            #expect(batteryItems.count == 1)
        }
    }

    let loader = ProfileLoader()
}
