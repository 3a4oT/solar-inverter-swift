// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// Date for device RTC time
#if canImport(FoundationEssentials)
    import FoundationEssentials
#else
    import Foundation
#endif

// MARK: - InverterInfo

/// Inverter device information and status.
public struct InverterInfo: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    /// Creates a new inverter info.
    public init(
        serialNumber: String? = nil,
        model: String? = nil,
        firmwareVersion: String? = nil,
        status: InverterStatus = .unknown,
        deviceTime: Date? = nil,
        dcTemperature: Double? = nil,
        acTemperature: Double? = nil,
        alarms: [InverterAlarm] = [],
        faults: [InverterAlarm] = [],
        ratedPower: Int? = nil,
        mpptCount: Int? = nil,
        phaseCount: Int? = nil,
    ) {
        self.serialNumber = serialNumber
        self.model = model
        self.firmwareVersion = firmwareVersion
        self.status = status
        self.deviceTime = deviceTime
        self.dcTemperature = dcTemperature
        self.acTemperature = acTemperature
        self.alarms = alarms
        self.faults = faults
        self.ratedPower = ratedPower
        self.mpptCount = mpptCount
        self.phaseCount = phaseCount
    }

    // MARK: Public

    /// Device serial number.
    public let serialNumber: String?

    /// Device model identifier.
    public let model: String?

    /// Firmware version.
    public let firmwareVersion: String?

    /// Current operating status.
    public let status: InverterStatus

    /// Device RTC (real-time clock) time.
    ///
    /// The inverter's internal clock, useful for:
    /// - Verifying time synchronization
    /// - Debugging time-of-use schedule issues
    /// - Correlating inverter logs with real time
    public let deviceTime: Date?

    /// DC-side (PV input) temperature in Celsius.
    public let dcTemperature: Double?

    /// AC-side (grid output) temperature in Celsius.
    public let acTemperature: Double?

    /// Active alarms (warnings).
    ///
    /// From "Device Alarm" sensor - fan failure, grid phase failure, etc.
    public let alarms: [InverterAlarm]

    /// Active faults (errors).
    ///
    /// From "Device Fault" sensor - over-current, temperature, etc.
    public let faults: [InverterAlarm]

    // MARK: - Device Configuration

    /// Rated output power in Watts.
    public let ratedPower: Int?

    /// Number of MPPT (Maximum Power Point Tracking) inputs.
    ///
    /// Typical values: 1-4 for residential, up to 12 for commercial.
    public let mpptCount: Int?

    /// Number of AC phases (1 or 3).
    public let phaseCount: Int?
}

// MARK: - InverterStatus

/// Inverter operating status.
public enum InverterStatus: String, Sendable, Codable {
    /// Inverter is in standby mode.
    case standby

    /// Inverter is running normally.
    case running

    /// Inverter has detected a fault.
    case fault

    /// Status could not be determined.
    case unknown
}

// MARK: - InverterAlarm

/// Inverter alarm or fault with bit position and description.
///
/// Extracted from "Device Alarm" and "Device Fault" bit-based sensors.
/// Each active bit in the register produces one alarm entry.
public struct InverterAlarm: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    /// Creates a new alarm.
    public init(bit: Int, description: String) {
        self.bit = bit
        self.description = description
    }

    // MARK: Public

    /// Bit position in the alarm/fault register (0-63).
    public let bit: Int

    /// Human-readable alarm description from profile lookup.
    public let description: String
}
