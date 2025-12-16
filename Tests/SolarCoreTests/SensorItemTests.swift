// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

@testable import SolarCore
import Testing

/// Tests for SensorItem computed properties and validation methods.
@Suite("SensorItem")
struct SensorItemTests {
    @Suite("Computed Properties")
    struct ComputedPropertiesTests {
        @Test("isReadOnly returns true for sensor platform")
        func isReadOnlySensor() {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                platform: .sensor,
            )
            #expect(item.isReadOnly == true)
        }

        @Test("isReadOnly returns false for number platform")
        func isReadOnlyNumber() {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                platform: .number,
            )
            #expect(item.isReadOnly == false)
        }

        @Test("isComputed returns true for computed rule")
        func isComputedRule() {
            let item = SensorItem(
                name: "Test",
                registers: [],
                rule: .computed,
            )
            #expect(item.isComputed == true)
        }

        @Test("isComputed returns true for empty registers")
        func isComputedEmptyRegisters() {
            let item = SensorItem(
                name: "Test",
                registers: [],
                rule: .uint16,
            )
            #expect(item.isComputed == true)
        }

        @Test("isComputed returns false for normal sensor")
        func isComputedFalse() {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
            )
            #expect(item.isComputed == false)
        }

        @Test("hasLookup returns true when lookup exists")
        func hasLookupTrue() {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                lookup: [LookupEntry(key: 0, value: "Off")],
            )
            #expect(item.hasLookup == true)
        }

        @Test("hasLookup returns false when lookup empty")
        func hasLookupFalse() {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
            )
            #expect(item.hasLookup == false)
        }

        @Test("isComposite returns true with subSensors")
        func isCompositeTrue() {
            let subSensor = SensorItem.SubSensor(
                registers: [0x0001],
                scale: 1.0,
                offset: 0.0,
                signed: false,
                operator: .add,
            )
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                subSensors: [subSensor],
            )
            #expect(item.isComposite == true)
        }

        @Test("isComposite returns false without subSensors")
        func isCompositeFalse() {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
            )
            #expect(item.isComposite == false)
        }

        @Test("startAddress returns minimum register")
        func startAddress() {
            let item = SensorItem(
                name: "Test",
                registers: [0x0010, 0x0005, 0x0020],
                rule: .uint32,
            )
            #expect(item.startAddress == 0x0005)
        }

        @Test("startAddress returns nil for empty registers")
        func startAddressNil() {
            let item = SensorItem(
                name: "Test",
                registers: [],
                rule: .computed,
            )
            #expect(item.startAddress == nil)
        }

        @Test("endAddress returns maximum register")
        func endAddress() {
            let item = SensorItem(
                name: "Test",
                registers: [0x0010, 0x0005, 0x0020],
                rule: .uint32,
            )
            #expect(item.endAddress == 0x0020)
        }

        @Test("registerCount returns count")
        func registerCount() {
            let item = SensorItem(
                name: "Test",
                registers: [0x0010, 0x0011, 0x0012],
                rule: .uint32,
            )
            #expect(item.registerCount == 3)
        }

        @Test("normalizedId converts to snake_case")
        func normalizedId() {
            let item = SensorItem(
                name: "Battery SOC",
                registers: [0x0000],
                rule: .uint16,
            )
            #expect(item.normalizedId == "battery_soc")
        }

        @Test("normalizedId handles hyphens")
        func normalizedIdHyphens() {
            let item = SensorItem(
                name: "Grid-L1-Voltage",
                registers: [0x0000],
                rule: .uint16,
            )
            #expect(item.normalizedId == "grid_l1_voltage")
        }

        @Test("normalizedId handles mixed case")
        func normalizedIdMixedCase() {
            let item = SensorItem(
                name: "PV1 Power",
                registers: [0x0000],
                rule: .uint16,
            )
            #expect(item.normalizedId == "pv1_power")
        }

        @Test("normalizedId handles space-hyphen-space pattern")
        func normalizedIdSpaceHyphenSpace() {
            // "Generator Energy - today" has " - " which becomes "___" (3 underscores)
            let item = SensorItem(
                name: "Generator Energy - today",
                registers: [0x0000],
                rule: .uint16,
            )
            #expect(item.normalizedId == "generator_energy___today")
        }
    }

    // MARK: - Range Validation

    @Suite("Range Validation")
    struct RangeValidationTests {
        @Test("isInRange with min only - value above")
        func isInRangeMinOnlyAbove() {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                rangeMin: 100,
            )
            #expect(item.isInRange(150) == true)
        }

        @Test("isInRange with min only - value below")
        func isInRangeMinOnlyBelow() {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                rangeMin: 100,
            )
            #expect(item.isInRange(50) == false)
        }

        @Test("isInRange with max only - value below")
        func isInRangeMaxOnlyBelow() {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                rangeMax: 1000,
            )
            #expect(item.isInRange(500) == true)
        }

        @Test("isInRange with max only - value above")
        func isInRangeMaxOnlyAbove() {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                rangeMax: 1000,
            )
            #expect(item.isInRange(1500) == false)
        }

        @Test("isInRange with both bounds - value inside")
        func isInRangeBothInside() {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                rangeMin: 100,
                rangeMax: 1000,
            )
            #expect(item.isInRange(500) == true)
        }

        @Test("isInRange with no bounds - always true")
        func isInRangeNoBounds() {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
            )
            #expect(item.isInRange(Double.infinity) == true)
        }
    }

    // MARK: - Transform

    @Suite("Transform")
    struct TransformTests {
        @Test("transform applies offset and scale")
        func transformOffsetScale() {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                scale: 0.1,
                offset: 1000,
            )
            // (1250 - 1000) * 0.1 = 25.0
            #expect(item.transform(1250) == 25.0)
        }

        @Test("transform with inverse negates result")
        func transformInverse() {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                scale: 1.0,
                inverse: true,
            )
            #expect(item.transform(100) == -100.0)
        }

        @Test("transform with zero offset")
        func transformZeroOffset() {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                scale: 0.01,
            )
            // (500 - 0) * 0.01 = 5.0
            #expect(item.transform(500) == 5.0)
        }
    }

    // MARK: - Validation (Post-Transform)

    @Suite("Post-Transform Validation")
    struct PostTransformValidationTests {
        @Test("isValid with min only - value above")
        func isValidMinOnlyAbove() {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                validationMin: 0,
            )
            #expect(item.isValid(50) == true)
        }

        @Test("isValid with min only - value below")
        func isValidMinOnlyBelow() {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                validationMin: 0,
            )
            #expect(item.isValid(-10) == false)
        }

        @Test("isValid with max only - value above")
        func isValidMaxOnlyAbove() {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                validationMax: 100,
            )
            #expect(item.isValid(150) == false)
        }

        @Test("isValid with no bounds - always true")
        func isValidNoBounds() {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
            )
            #expect(item.isValid(Double.nan) == true)
        }
    }

    // MARK: - Lookup

    @Suite("Lookup")
    struct LookupTests {
        @Test("lookupValue returns matching value")
        func lookupValueFound() {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                lookup: [
                    LookupEntry(key: 0, value: "Standby"),
                    LookupEntry(key: 1, value: "Running"),
                ],
            )
            #expect(item.lookupValue(for: 1) == "Running")
        }

        @Test("lookupValue returns nil for unknown key")
        func lookupValueNotFound() {
            let item = SensorItem(
                name: "Test",
                registers: [0x0000],
                rule: .uint16,
                lookup: [
                    LookupEntry(key: 0, value: "Standby"),
                ],
            )
            #expect(item.lookupValue(for: 99) == nil)
        }
    }
}
