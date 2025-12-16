// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// FoundationEssentials: Date
// FoundationInternationalization: TimeZone, Date.ParseStrategy
#if canImport(FoundationEssentials)
    import FoundationEssentials
    import FoundationInternationalization
#else
    import Foundation
#endif

extension StatusBuilder {
    // MARK: Internal

    /// Build `InverterInfo` from registers and items.
    func buildInverter(
        from registers: [UInt16: UInt16],
        items: [SensorItem],
    ) -> InverterInfo? {
        // Extract numeric values
        let values = extractValues(from: registers, items: items)

        // Serial number (ASCII sensor)
        let serialNumber = extractSerialNumber(from: registers, items: items)

        // Status with lookup → convert to enum
        let status = extractInverterStatus(from: registers, items: items)

        // Model from "Device" lookup sensor
        let model = extractDeviceModel(from: registers, items: items)

        // Firmware version from version sensors
        let firmwareVersion = extractFirmwareVersion(from: registers, items: items)

        // Alarms and faults from bit-based sensors
        let alarms = extractBitAlarms(from: registers, items: items, sensorName: "device_alarm")
        let faults = extractBitAlarms(from: registers, items: items, sensorName: "device_fault")

        // Device RTC time
        let deviceTime = extractDeviceTime(from: registers, items: items)

        // Device configuration
        let ratedPower = extractRatedPower(from: values)
        let mpptCount = extractMpptCount(from: values)
        let phaseCount = extractPhaseCount(from: values)

        typealias K = SensorKeys.Inverter

        // Return nil if nothing to report
        guard serialNumber != nil || model != nil || firmwareVersion != nil || !values.isEmpty else {
            return nil
        }

        return InverterInfo(
            serialNumber: serialNumber,
            model: model,
            firmwareVersion: firmwareVersion,
            status: status,
            deviceTime: deviceTime,
            dcTemperature: values[K.dcTemperature],
            acTemperature: values[K.acTemperature],
            alarms: alarms,
            faults: faults,
            ratedPower: ratedPower,
            mpptCount: mpptCount,
            phaseCount: phaseCount,
        )
    }

    /// Extract Device State label from registers (used by both InverterStatus and UPSMode).
    func extractDeviceStateLabel(
        from registers: [UInt16: UInt16],
        items: [SensorItem],
    ) -> String? {
        // Find status sensor with lookup
        // Upstream: "Device State" or "Running Status" → "device_state" or "running_status"
        guard
            let item = items.first(where: {
                ($0.normalizedId.contains("status") || $0.normalizedId.contains("state"))
                    && !$0.lookup.isEmpty
            }),
            let sensorRegisters = extractRegisters(for: item, from: registers),
            let rawValue = sensorRegisters.first
        else {
            return nil
        }

        return item.lookupValue(for: Int(rawValue))
    }

    // MARK: Private

    private func extractDeviceTime(
        from registers: [UInt16: UInt16],
        items: [SensorItem],
    ) -> Date? {
        // Find datetime sensor
        // Upstream: "Date & Time" → "date_&_time" with rule 8 (datetime)
        guard
            let item = items.first(where: {
                $0.normalizedId == "date_&_time" || $0.normalizedId == "device_time"
            }),
            item.rule == .datetime,
            let sensorRegisters = extractRegisters(for: item, from: registers),
            let datetimeString = converter.convertDateTime(registers: sensorRegisters)
        else {
            return nil
        }

        // Parse "YY/MM/DD HH:MM:SS" format
        return parseDeviceTime(datetimeString)
    }

    private func parseDeviceTime(_ string: String) -> Date? {
        // Format: "YY/MM/DD HH:MM:SS" (e.g., "24/12/15 14:30:00")
        let strategy = Date.ParseStrategy(
            format: "\(year: .twoDigits)/\(month: .twoDigits)/\(day: .twoDigits) \(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits):\(second: .twoDigits)",
            timeZone: .gmt,
        )
        return try? Date(string, strategy: strategy)
    }

    private func extractSerialNumber(
        from registers: [UInt16: UInt16],
        items: [SensorItem],
    ) -> String? {
        // Find ASCII sensor with serial number
        // Upstream: "Serial Number" → "serial_number"
        guard
            let item = items.first(where: {
                $0.normalizedId == "serial_number" || $0.normalizedId == "device_serial_number"
            }),
            item.rule == .ascii,
            let sensorRegisters = extractRegisters(for: item, from: registers)
        else {
            return nil
        }

        return try? converter.convertString(registers: sensorRegisters)
    }

    private func extractInverterStatus(
        from registers: [UInt16: UInt16],
        items: [SensorItem],
    ) -> InverterStatus {
        guard let label = extractDeviceStateLabel(from: registers, items: items) else {
            return .unknown
        }

        // Map lookup label to InverterStatus enum
        switch label.lowercased() {
        case "standby",
             "stand-by",
             "waiting":
            return .standby
        case "running",
             "normal",
             "generating",
             "on-grid",
             "charging",
             "discharging",
             "charging check",
             "discharging check",
             "emergency power supply": // EPS mode - inverter is still running
            return .running
        case "fault",
             "alarm",
             "error",
             "failure",
             "permanent fault",
             "recoverable fault":
            return .fault
        default:
            return .unknown
        }
    }

    private func extractDeviceModel(
        from registers: [UInt16: UInt16],
        items: [SensorItem],
    ) -> String? {
        // Find "Device" sensor with lookup for model type
        // Upstream: "Device" → "device" with lookup values like "LV 3-Phase Hybrid Inverter"
        guard
            let item = items.first(where: {
                $0.normalizedId == "device" && !$0.lookup.isEmpty
            }),
            let sensorRegisters = extractRegisters(for: item, from: registers),
            let rawValue = sensorRegisters.first,
            let label = item.lookupValue(for: Int(rawValue))
        else {
            return nil
        }

        return label
    }

    private func extractFirmwareVersion(
        from registers: [UInt16: UInt16],
        items: [SensorItem],
    ) -> String? {
        // Try multiple firmware version sensors
        // Upstream: "Device Control Board Firmware Version" → rule 7 (version)
        let versionKeys = [
            "device_control_board_firmware_version",
            "device_communication_board_firmware_version",
            "firmware_version",
            "software_version",
        ]

        for key in versionKeys {
            guard
                let item = items.first(where: { $0.normalizedId == key }),
                item.rule == .version,
                let sensorRegisters = extractRegisters(for: item, from: registers)
            else {
                continue
            }

            // Use delimiter and hex settings from sensor item
            let version = converter.convertVersion(
                registers: sensorRegisters,
                delimiter: item.versionDelimiter,
                hex: item.hex,
            )
            if !version.isEmpty {
                return version
            }
        }

        return nil
    }

    /// Extract rated power from values.
    ///
    /// Upstream: "Device Rated Power" → "device_rated_power"
    /// Scale is already applied by RegisterConverter (0.1 → Watts).
    private func extractRatedPower(from values: SensorValues) -> Int? {
        values.int(SensorKeys.Inverter.ratedPower)
    }

    /// Extract MPPT count from values.
    ///
    /// Upstream: "Device MPPTs" → "device_mppts"
    /// Mask (0x0F00) and divide (256) already applied by RegisterConverter.
    private func extractMpptCount(from values: SensorValues) -> Int? {
        values.int(SensorKeys.Inverter.mpptCount)
    }

    /// Extract phase count from values.
    ///
    /// Upstream: "Device Phases" → "device_phases"
    /// Mask (0x000F) already applied by RegisterConverter.
    private func extractPhaseCount(from values: SensorValues) -> Int? {
        values.int(SensorKeys.Inverter.phaseCount)
    }

    /// Extract active alarms from bit-based sensor.
    ///
    /// Sensors like "Device Alarm" and "Device Fault" use bit positions in lookup:
    /// ```yaml
    /// lookup:
    ///   - key: 0
    ///     value: "OK"
    ///   - bit: 1
    ///     value: "Fan failure"
    ///   - bit: 2
    ///     value: "Grid phase failure"
    /// ```
    ///
    /// This method reads the raw register value and returns all active bits
    /// that have descriptions in the lookup.
    private func extractBitAlarms(
        from registers: [UInt16: UInt16],
        items: [SensorItem],
        sensorName: String,
    ) -> [InverterAlarm] {
        guard
            let item = items.first(where: { $0.normalizedId == sensorName }),
            !item.lookup.isEmpty,
            let sensorRegisters = extractRegisters(for: item, from: registers)
        else {
            return []
        }

        // Combine registers into 32-bit or 64-bit value using Little Endian word order
        // ha-solarman uses CDAB (first register is LSW)
        guard let rawValue = decodeRegistersLE(sensorRegisters), rawValue != 0 else {
            return []
        }

        // Find all active bits with descriptions
        var alarms: [InverterAlarm] = []

        for entry in item.lookup {
            if case let .bit(position) = entry.key {
                // Check if bit is set
                if position < 64, (rawValue & (1 << position)) != 0 {
                    alarms.append(InverterAlarm(bit: position, description: entry.value))
                }
            }
        }

        return alarms
    }
}
