// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - TimeOfUseSchedule

/// Time-of-Use (TOU) schedule configuration.
///
/// Defines charging/discharging schedules based on electricity tariffs.
/// Most inverters support 6 programmable time slots.
public struct TimeOfUseSchedule: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    /// Creates a new time-of-use schedule.
    public init(
        slots: [TimeSlot],
        sellingSchedule: WeeklySchedule? = nil,
    ) {
        self.slots = slots
        self.sellingSchedule = sellingSchedule
    }

    // MARK: Public

    /// Programmed time slots (up to 6).
    public let slots: [TimeSlot]

    /// Weekly selling schedule flags.
    public let sellingSchedule: WeeklySchedule?
}

// MARK: - TimeSlot

/// Single time-of-use slot configuration.
public struct TimeSlot: Sendable, Equatable {
    // MARK: Lifecycle

    /// Creates a new time slot.
    public init(
        id: Int,
        startTime: Int,
        endTime: Int,
        isEnabled: Bool,
        targetSOC: Int? = nil,
        chargePower: Int? = nil,
        chargeVoltage: Double? = nil,
        mode: TimeSlotMode? = nil,
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.isEnabled = isEnabled
        self.targetSOC = targetSOC
        self.chargePower = chargePower
        self.chargeVoltage = chargeVoltage
        self.mode = mode
    }

    // MARK: Public

    /// Slot identifier (1-6).
    public let id: Int

    /// Start time (minutes from midnight, 0-1439).
    public let startTime: Int

    /// End time (minutes from midnight, 0-1439).
    public let endTime: Int

    /// Whether this slot is enabled.
    public let isEnabled: Bool

    /// Target SOC percentage for this slot.
    public let targetSOC: Int?

    /// Charge power limit in Watts.
    public let chargePower: Int?

    /// Grid charge voltage threshold in Volts.
    public let chargeVoltage: Double?

    /// Operating mode for this slot.
    public let mode: TimeSlotMode?

    /// Start time formatted as "HH:MM".
    public var startTimeFormatted: String {
        formatMinutes(startTime)
    }

    /// End time formatted as "HH:MM".
    public var endTimeFormatted: String {
        formatMinutes(endTime)
    }

    // MARK: Private

    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return String(format: "%02d:%02d", hours, mins)
    }
}

// MARK: Codable

extension TimeSlot: Codable {
    // MARK: Lifecycle

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        startTime = try container.decode(Int.self, forKey: .startTime)
        endTime = try container.decode(Int.self, forKey: .endTime)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        targetSOC = try container.decodeIfPresent(Int.self, forKey: .targetSOC)
        chargePower = try container.decodeIfPresent(Int.self, forKey: .chargePower)
        chargeVoltage = try container.decodeIfPresent(Double.self, forKey: .chargeVoltage)
        mode = try container.decodeIfPresent(TimeSlotMode.self, forKey: .mode)
        // Formatted fields are computed, ignore on decode
    }

    // MARK: Public

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encodeIfPresent(targetSOC, forKey: .targetSOC)
        try container.encodeIfPresent(chargePower, forKey: .chargePower)
        try container.encodeIfPresent(chargeVoltage, forKey: .chargeVoltage)
        try container.encodeIfPresent(mode, forKey: .mode)
        // Include formatted times in JSON output
        try container.encode(startTimeFormatted, forKey: .startTimeFormatted)
        try container.encode(endTimeFormatted, forKey: .endTimeFormatted)
    }

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case id
        case startTime
        case endTime
        case isEnabled
        case targetSOC
        case chargePower
        case chargeVoltage
        case mode
        case startTimeFormatted
        case endTimeFormatted
    }
}

// MARK: - TimeSlotMode

/// Time slot operating mode.
public enum TimeSlotMode: String, Sendable, Codable {
    /// Grid charging allowed.
    case gridCharge

    /// Battery discharge to grid (sell).
    case sell

    /// Self-consumption only.
    case selfConsumption

    /// Battery charging from PV only.
    case pvCharge

    /// Standby (no action).
    case standby
}

// MARK: - WeeklySchedule

/// Weekly schedule flags.
public struct WeeklySchedule: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    /// Creates a weekly schedule from individual day flags.
    public init(
        monday: Bool = false,
        tuesday: Bool = false,
        wednesday: Bool = false,
        thursday: Bool = false,
        friday: Bool = false,
        saturday: Bool = false,
        sunday: Bool = false,
    ) {
        self.monday = monday
        self.tuesday = tuesday
        self.wednesday = wednesday
        self.thursday = thursday
        self.friday = friday
        self.saturday = saturday
        self.sunday = sunday
    }

    /// Creates a weekly schedule from a bitmask (bit 0 = Monday).
    public init(bitmask: Int) {
        monday = (bitmask & 0x01) != 0
        tuesday = (bitmask & 0x02) != 0
        wednesday = (bitmask & 0x04) != 0
        thursday = (bitmask & 0x08) != 0
        friday = (bitmask & 0x10) != 0
        saturday = (bitmask & 0x20) != 0
        sunday = (bitmask & 0x40) != 0
    }

    // MARK: Public

    public let monday: Bool
    public let tuesday: Bool
    public let wednesday: Bool
    public let thursday: Bool
    public let friday: Bool
    public let saturday: Bool
    public let sunday: Bool

    /// Returns the schedule as a bitmask.
    public var bitmask: Int {
        var result = 0
        if monday {
            result |= 0x01
        }
        if tuesday {
            result |= 0x02
        }
        if wednesday {
            result |= 0x04
        }
        if thursday {
            result |= 0x08
        }
        if friday {
            result |= 0x10
        }
        if saturday {
            result |= 0x20
        }
        if sunday {
            result |= 0x40
        }
        return result
    }
}
