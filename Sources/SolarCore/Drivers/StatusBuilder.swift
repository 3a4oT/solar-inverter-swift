// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// Foundation needed for Date in SolarStatus.timestamp
#if canImport(FoundationEssentials)
    import FoundationEssentials
#else
    import Foundation
#endif

// MARK: - StatusBuilder

/// Builds `SolarStatus` from raw register values using profile definitions.
///
/// ## Security
/// - All register access via Dictionary lookup (safe, returns nil)
/// - Missing optional sensors skipped
/// - No force unwrapping
public struct StatusBuilder: Sendable {
    // MARK: Lifecycle

    public init(converter: RegisterConverter = RegisterConverter()) {
        self.converter = converter
    }

    // MARK: Public

    /// Build `SolarStatus` from raw register values.
    public func build(
        from registerValues: [UInt16: UInt16],
        profile: InverterDefinition,
        groups: Set<SensorGroup>,
    ) throws(DriverError) -> SolarStatus {
        // Collect all items for requested groups
        let allItems = groups.flatMap { group -> [SensorItem] in
            group.upstreamGroupNames.flatMap { profile.items(inGroup: $0) }
        }

        // Extract all numeric values
        let values = extractValues(from: registerValues, items: allItems)

        // Extract Device State label for UPS mode determination
        let deviceStateLabel = extractDeviceStateLabel(from: registerValues, items: allItems)

        return SolarStatus(
            timestamp: Date(),
            battery: groups.contains(.battery)
                ? buildBattery(from: values)
                : nil,
            grid: groups.contains(.grid)
                ? buildGrid(from: values)
                : nil,
            pv: groups.contains(.pv)
                ? buildPV(from: values)
                : nil,
            load: groups.contains(.load)
                ? buildLoad(from: values)
                : nil,
            inverter: groups.contains(.inverter)
                ? buildInverter(from: registerValues, items: allItems)
                : nil,
            generator: groups.contains(.generator)
                ? buildGenerator(from: values)
                : nil,
            ups: groups.contains(.ups)
                ? buildUPS(from: values, deviceStateLabel: deviceStateLabel)
                : nil,
            bms: groups.contains(.bms)
                ? buildBMS(from: values)
                : nil,
            timeOfUse: groups.contains(.timeOfUse)
                ? buildTimeOfUse(from: values)
                : nil,
        )
    }

    // MARK: Internal

    let converter: RegisterConverter
}

// MARK: - Safe Register Extraction

extension StatusBuilder {
    /// Safely extract registers for a sensor item.
    /// Returns nil if ANY address is missing (defense in depth).
    func extractRegisters(
        for item: SensorItem,
        from registerValues: [UInt16: UInt16],
    ) -> [UInt16]? {
        let registers = item.registers.compactMap { registerValues[$0] }
        guard registers.count == item.registers.count else {
            return nil
        }
        return registers
    }

    /// Extract numeric values from sensor items.
    ///
    /// Returns `SensorValues` wrapper for type-safe key access.
    func extractValues(
        from registers: [UInt16: UInt16],
        items: [SensorItem],
    ) -> SensorValues {
        // Convert all available numeric sensors
        let pairs: [(String, Double)] = items.compactMap { item in
            // Skip sensors with empty names (ha-solarman uses empty names for device-level sensors)
            guard !item.normalizedId.isEmpty else {
                return nil
            }

            // Skip non-numeric rules
            guard item.rule.isNumeric else {
                return nil
            }

            // Safe extraction
            guard let sensorRegisters = extractRegisters(for: item, from: registers) else {
                return nil
            }

            // Convert (skip on error for optional sensors)
            guard let value = try? converter.convert(registers: sensorRegisters, item: item) else {
                return nil
            }

            return (item.normalizedId, value)
        }

        // Use first value for duplicate keys (some profiles have duplicate sensor names)
        let raw = Dictionary(pairs, uniquingKeysWith: { first, _ in first })
        return SensorValues(raw)
    }
}
