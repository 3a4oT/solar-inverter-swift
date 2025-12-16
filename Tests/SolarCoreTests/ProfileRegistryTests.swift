// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

@testable import SolarCore
import Testing

/// Tests for ProfileRegistry - automatic inverter profile matching.
///
/// Validates:
/// - Exact and pattern matching
/// - Security validation (control characters, length limits)
/// - Fallback suggestions
@Suite("ProfileRegistry")
struct ProfileRegistryTests {
    // MARK: - Exact Matching

    @Suite("Exact Matching")
    struct ExactMatchTests {
        @Test("Exact model match found")
        func exactMatch() {
            let registry = ProfileRegistry(profiles: testProfiles)
            let device = DeviceInfo(
                manufacturer: "SOLIS",
                model: "S5-EH1P",
                serial: "123456",
            )

            let result = registry.find(for: device)

            if case let .found(profile) = result {
                #expect(profile.id == "solis_5g")
            } else {
                Issue.record("Expected .found result")
            }
        }

        @Test("Case insensitive manufacturer match")
        func caseInsensitiveManufacturer() {
            let registry = ProfileRegistry(profiles: testProfiles)
            let device = DeviceInfo(
                manufacturer: "deye", // lowercase
                model: "SUN-12K-SG04LP3",
                serial: "123456",
            )

            let result = registry.find(for: device)

            if case let .found(profile) = result {
                #expect(profile.id == "deye_sun_12k")
            } else {
                Issue.record("Expected .found result")
            }
        }

        @Test("Case insensitive model match")
        func caseInsensitiveModel() {
            let registry = ProfileRegistry(profiles: testProfiles)
            let device = DeviceInfo(
                manufacturer: "SOLIS",
                model: "s5-eh1p", // lowercase
                serial: "123456",
            )

            let result = registry.find(for: device)

            if case let .found(profile) = result {
                #expect(profile.id == "solis_5g")
            } else {
                Issue.record("Expected .found result")
            }
        }
    }

    // MARK: - Pattern Matching

    @Suite("Pattern Matching")
    struct PatternMatchTests {
        @Test("Wildcard suffix match")
        func wildcardSuffix() {
            let registry = ProfileRegistry(profiles: testProfiles)
            let device = DeviceInfo(
                manufacturer: "DEYE",
                model: "SUN-12K-SG04LP3-EU", // With EU suffix
                serial: "123456",
            )

            let result = registry.find(for: device)

            if case let .found(profile) = result {
                #expect(profile.id == "deye_sun_12k")
            } else {
                Issue.record("Expected .found result")
            }
        }

        @Test("Multiple wildcards match")
        func multipleWildcards() {
            let registry = ProfileRegistry(profiles: testProfiles)
            let device = DeviceInfo(
                manufacturer: "DEYE",
                model: "SUN-6K-SG01LP3-US", // Different power, different suffix
                serial: "123456",
            )

            let result = registry.find(for: device)

            // Should match generic pattern SUN-*-SG*LP3*
            if case let .found(profile) = result {
                #expect(profile.id == "deye_hybrid_generic")
            } else {
                Issue.record("Expected .found result for generic pattern")
            }
        }

        @Test("More specific pattern matched first")
        func specificPatternFirst() {
            let registry = ProfileRegistry(profiles: testProfiles)
            let device = DeviceInfo(
                manufacturer: "DEYE",
                model: "SUN-8K-SG04LP3-EU",
                serial: "123456",
            )

            let result = registry.find(for: device)

            // Should match specific SUN-8K pattern, not generic
            if case let .found(profile) = result {
                #expect(profile.id == "deye_sun_8k")
            } else {
                Issue.record("Expected .found result")
            }
        }

        @Test("Victron pattern match")
        func victronPattern() {
            let registry = ProfileRegistry(profiles: testProfiles)
            let device = DeviceInfo(
                manufacturer: "VICTRON",
                model: "MultiPlus-II 48/5000/70-50",
                serial: "HQ2112ABC",
            )

            let result = registry.find(for: device)

            if case let .found(profile) = result {
                #expect(profile.id == "victron_multiplus")
            } else {
                Issue.record("Expected .found result")
            }
        }
    }

    // MARK: - Unsupported Devices

    @Suite("Unsupported Devices")
    struct UnsupportedTests {
        @Test("Unknown model from known manufacturer - suggestion provided")
        func unknownModelKnownManufacturer() {
            let registry = ProfileRegistry(profiles: testProfiles)
            let device = DeviceInfo(
                manufacturer: "DEYE",
                model: "MICRO-600", // Unknown model
                serial: "123456",
            )

            let result = registry.find(for: device)

            if case let .unsupported(suggestion) = result {
                // Should suggest a DEYE profile
                #expect(suggestion != nil)
                #expect(suggestion?.manufacturer == "DEYE")
            } else {
                Issue.record("Expected .unsupported result with suggestion")
            }
        }

        @Test("Unknown manufacturer - no suggestion")
        func unknownManufacturer() {
            let registry = ProfileRegistry(profiles: testProfiles)
            let device = DeviceInfo(
                manufacturer: "HUAWEI",
                model: "SUN2000-10KTL",
                serial: "123456",
            )

            let result = registry.find(for: device)

            if case .unknown = result {
                // Expected
            } else {
                Issue.record("Expected .unknown result")
            }
        }

        @Test("Empty profiles - unknown")
        func emptyProfiles() {
            let registry = ProfileRegistry(profiles: [])
            let device = DeviceInfo(
                manufacturer: "DEYE",
                model: "SUN-12K-SG04LP3",
                serial: "123456",
            )

            let result = registry.find(for: device)

            if case .unknown = result {
                // Expected
            } else {
                Issue.record("Expected .unknown result")
            }
        }
    }

    // MARK: - Security Validation

    @Suite("Security Validation")
    struct SecurityTests {
        @Test("Control character in manufacturer rejected")
        func controlCharInManufacturer() {
            let registry = ProfileRegistry(profiles: testProfiles)
            let device = DeviceInfo(
                manufacturer: "DEYE\t", // Tab character
                model: "SUN-12K-SG04LP3",
                serial: "123456",
            )

            let result = registry.find(for: device)

            if case .unknown = result {
                // Expected - rejected for security
            } else {
                Issue.record("Expected .unknown for control character input")
            }
        }

        @Test("Control character in model rejected")
        func controlCharInModel() {
            let registry = ProfileRegistry(profiles: testProfiles)
            let device = DeviceInfo(
                manufacturer: "DEYE",
                model: "SUN-12K\nSG04LP3", // Newline character
                serial: "123456",
            )

            let result = registry.find(for: device)

            if case .unknown = result {
                // Expected - rejected for security
            } else {
                Issue.record("Expected .unknown for control character input")
            }
        }

        @Test("Null character rejected")
        func nullCharacterRejected() {
            let registry = ProfileRegistry(profiles: testProfiles)
            let device = DeviceInfo(
                manufacturer: "DEYE\0FAKE",
                model: "SUN-12K-SG04LP3",
                serial: "123456",
            )

            let result = registry.find(for: device)

            if case .unknown = result {
                // Expected
            } else {
                Issue.record("Expected .unknown for null character input")
            }
        }

        @Test("DEL character (0x7F) rejected")
        func delCharacterRejected() {
            let registry = ProfileRegistry(profiles: testProfiles)
            let device = DeviceInfo(
                manufacturer: "DEYE\u{7F}",
                model: "SUN-12K-SG04LP3",
                serial: "123456",
            )

            let result = registry.find(for: device)

            if case .unknown = result {
                // Expected
            } else {
                Issue.record("Expected .unknown for DEL character input")
            }
        }

        @Test("C1 control character (0x80-0x9F) rejected")
        func c1ControlRejected() {
            let registry = ProfileRegistry(profiles: testProfiles)
            let device = DeviceInfo(
                manufacturer: "DEYE\u{85}", // NEL (Next Line)
                model: "SUN-12K-SG04LP3",
                serial: "123456",
            )

            let result = registry.find(for: device)

            if case .unknown = result {
                // Expected
            } else {
                Issue.record("Expected .unknown for C1 control character input")
            }
        }

        @Test("UTF-8 characters allowed")
        func utf8Allowed() {
            let profiles = [
                ProfileReference(
                    id: "test_ukr",
                    name: "Тестовий профіль",
                    manufacturer: "Укрінвертор",
                    modelPattern: "УІ-*",
                ),
            ]
            let registry = ProfileRegistry(profiles: profiles)
            let device = DeviceInfo(
                manufacturer: "Укрінвертор",
                model: "УІ-5000",
                serial: "123456",
            )

            let result = registry.find(for: device)

            if case let .found(profile) = result {
                #expect(profile.id == "test_ukr")
            } else {
                Issue.record("Expected .found for valid UTF-8 input")
            }
        }

        @Test("Oversized manufacturer rejected")
        func oversizedManufacturer() {
            let registry = ProfileRegistry(profiles: testProfiles)
            let longString = String(repeating: "A", count: 200)
            let device = DeviceInfo(
                manufacturer: longString,
                model: "SUN-12K-SG04LP3",
                serial: "123456",
            )

            let result = registry.find(for: device)

            if case .unknown = result {
                // Expected - exceeds maxIdentifierLength (128)
            } else {
                Issue.record("Expected .unknown for oversized input")
            }
        }

        @Test("Oversized model rejected")
        func oversizedModel() {
            let registry = ProfileRegistry(profiles: testProfiles)
            let longString = String(repeating: "A", count: 200)
            let device = DeviceInfo(
                manufacturer: "DEYE",
                model: longString,
                serial: "123456",
            )

            let result = registry.find(for: device)

            if case .unknown = result {
                // Expected
            } else {
                Issue.record("Expected .unknown for oversized input")
            }
        }

        @Test("Exactly at max length allowed")
        func exactlyAtMaxLength() {
            let profiles = [
                ProfileReference(
                    id: "test",
                    name: "Test",
                    manufacturer: String(repeating: "A", count: 128),
                    modelPattern: "*",
                ),
            ]
            let registry = ProfileRegistry(profiles: profiles)
            let device = DeviceInfo(
                manufacturer: String(repeating: "A", count: 128),
                model: "TEST",
                serial: "123456",
            )

            let result = registry.find(for: device)

            if case .found = result {
                // Expected - exactly at limit should work
            } else {
                Issue.record("Expected .found for input at max length")
            }
        }
    }

    // MARK: - Supported Lists

    @Suite("Supported Lists")
    struct SupportedListsTests {
        @Test("supportedManufacturers returns unique sorted list")
        func supportedManufacturers() {
            let registry = ProfileRegistry(profiles: testProfiles)
            let manufacturers = registry.supportedManufacturers

            #expect(manufacturers == ["DEYE", "SOLIS", "VICTRON"])
        }

        @Test("supportedModels returns all patterns")
        func supportedModels() {
            let registry = ProfileRegistry(profiles: testProfiles)
            let models = registry.supportedModels

            #expect(models.count == 5)
            #expect(models.contains("SUN-12K-SG04LP3*"))
            #expect(models.contains("S5-EH1P*"))
        }

        @Test("Empty registry returns empty lists")
        func emptyRegistry() {
            let registry = ProfileRegistry(profiles: [])

            #expect(registry.supportedManufacturers.isEmpty)
            #expect(registry.supportedModels.isEmpty)
        }
    }

    // MARK: - Pattern Edge Cases

    @Suite("Pattern Edge Cases")
    struct PatternEdgeCaseTests {
        @Test("Pattern with only wildcard matches everything")
        func onlyWildcard() {
            let profiles = [
                ProfileReference(
                    id: "catch_all",
                    name: "Catch All",
                    manufacturer: "TEST",
                    modelPattern: "*",
                ),
            ]
            let registry = ProfileRegistry(profiles: profiles)
            let device = DeviceInfo(
                manufacturer: "TEST",
                model: "ANY-MODEL-123",
                serial: "123456",
            )

            let result = registry.find(for: device)

            if case let .found(profile) = result {
                #expect(profile.id == "catch_all")
            } else {
                Issue.record("Expected .found result")
            }
        }

        @Test("Pattern without wildcards requires exact match")
        func noWildcards() {
            let profiles = [
                ProfileReference(
                    id: "exact",
                    name: "Exact",
                    manufacturer: "TEST",
                    modelPattern: "EXACT-MODEL",
                ),
            ]
            let registry = ProfileRegistry(profiles: profiles)

            // Exact match works
            let result1 = registry.find(
                for: DeviceInfo(
                    manufacturer: "TEST",
                    model: "EXACT-MODEL",
                    serial: "123",
                ))
            if case .found = result1 {
                // Expected
            } else {
                Issue.record("Expected exact match to work")
            }

            // Partial match fails
            let result2 = registry.find(
                for: DeviceInfo(
                    manufacturer: "TEST",
                    model: "EXACT-MODEL-EXTRA",
                    serial: "123",
                ))
            if case .unsupported = result2 {
                // Expected - no pattern match
            } else {
                Issue.record("Expected partial match to fail")
            }
        }

        @Test("Multiple consecutive wildcards")
        func multipleWildcards() {
            let profiles = [
                ProfileReference(
                    id: "multi",
                    name: "Multi",
                    manufacturer: "TEST",
                    modelPattern: "A**B", // Double wildcard
                ),
            ]
            let registry = ProfileRegistry(profiles: profiles)
            let device = DeviceInfo(
                manufacturer: "TEST",
                model: "A-anything-B",
                serial: "123456",
            )

            let result = registry.find(for: device)

            if case .found = result {
                // Expected
            } else {
                Issue.record("Expected .found result")
            }
        }

        @Test("Leading wildcard")
        func leadingWildcard() {
            let profiles = [
                ProfileReference(
                    id: "suffix",
                    name: "Suffix Match",
                    manufacturer: "TEST",
                    modelPattern: "*-INVERTER",
                ),
            ]
            let registry = ProfileRegistry(profiles: profiles)
            let device = DeviceInfo(
                manufacturer: "TEST",
                model: "MODEL-123-INVERTER",
                serial: "123456",
            )

            let result = registry.find(for: device)

            if case .found = result {
                // Expected
            } else {
                Issue.record("Expected .found result")
            }
        }
    }

    // MARK: - Test Fixtures

    static let testProfiles: [ProfileReference] = [
        ProfileReference(
            id: "deye_sun_12k",
            name: "Deye SUN-12K-SG04LP3",
            manufacturer: "DEYE",
            modelPattern: "SUN-12K-SG04LP3*",
        ),
        ProfileReference(
            id: "deye_sun_8k",
            name: "Deye SUN-8K-SG04LP3",
            manufacturer: "DEYE",
            modelPattern: "SUN-8K-SG04LP3*",
        ),
        ProfileReference(
            id: "deye_hybrid_generic",
            name: "Deye Hybrid Generic",
            manufacturer: "DEYE",
            modelPattern: "SUN-*-SG*LP3*",
        ),
        ProfileReference(
            id: "solis_5g",
            name: "Solis 5G Hybrid",
            manufacturer: "SOLIS",
            modelPattern: "S5-EH1P*",
        ),
        ProfileReference(
            id: "victron_multiplus",
            name: "Victron MultiPlus-II",
            manufacturer: "VICTRON",
            modelPattern: "MultiPlus-II*",
        ),
    ]
}
