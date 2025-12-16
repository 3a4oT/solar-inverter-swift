// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - BMSStatus

/// Battery Management System (BMS) detailed status.
///
/// Provides detailed information from the battery's BMS,
/// including charging limits, cell-level data, and health metrics.
/// Some inverters support multiple BMS units (BMS1, BMS2).
public struct BMSStatus: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    /// Creates a new BMS status.
    public init(
        unit: Int = 1,
        isConnected: Bool = true,
        soc: Int,
        soh: Int? = nil,
        voltage: Double,
        current: Double,
        temperature: Double? = nil,
        chargingVoltage: Double? = nil,
        dischargeVoltage: Double? = nil,
        maxChargeCurrent: Double? = nil,
        maxDischargeCurrent: Double? = nil,
        chargeCurrentLimit: Double? = nil,
        dischargeCurrentLimit: Double? = nil,
        cells: CellInfo? = nil,
        cycles: Int? = nil,
        alarms: [BMSAlarm] = [],
    ) {
        self.unit = unit
        self.isConnected = isConnected
        self.soc = soc
        self.soh = soh
        self.voltage = voltage
        self.current = current
        self.temperature = temperature
        self.chargingVoltage = chargingVoltage
        self.dischargeVoltage = dischargeVoltage
        self.maxChargeCurrent = maxChargeCurrent
        self.maxDischargeCurrent = maxDischargeCurrent
        self.chargeCurrentLimit = chargeCurrentLimit
        self.dischargeCurrentLimit = dischargeCurrentLimit
        self.cells = cells
        self.cycles = cycles
        self.alarms = alarms
    }

    // MARK: Public

    /// BMS unit identifier (1 or 2 for dual-BMS systems).
    public let unit: Int

    /// BMS communication status.
    public let isConnected: Bool

    /// State of charge from BMS (%).
    public let soc: Int

    /// State of health (%).
    public let soh: Int?

    /// Battery voltage from BMS in Volts.
    public let voltage: Double

    /// Battery current from BMS in Amps.
    public let current: Double

    /// Battery temperature from BMS in Celsius.
    public let temperature: Double?

    /// Charging voltage limit in Volts.
    public let chargingVoltage: Double?

    /// Discharge voltage limit in Volts.
    public let dischargeVoltage: Double?

    /// Maximum charge current limit in Amps.
    public let maxChargeCurrent: Double?

    /// Maximum discharge current limit in Amps.
    public let maxDischargeCurrent: Double?

    /// Charge current limit from BMS in Amps.
    public let chargeCurrentLimit: Double?

    /// Discharge current limit from BMS in Amps.
    public let dischargeCurrentLimit: Double?

    /// Cell-level information (if available).
    public let cells: CellInfo?

    /// Total charge/discharge cycles.
    public let cycles: Int?

    /// BMS alarm flags.
    public let alarms: [BMSAlarm]
}

// MARK: - CellInfo

/// Cell-level battery information.
public struct CellInfo: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    /// Creates cell info.
    public init(
        cellCount: Int,
        minVoltage: Double,
        maxVoltage: Double,
        voltageDelta: Int,
        minTemperature: Double? = nil,
        maxTemperature: Double? = nil,
    ) {
        self.cellCount = cellCount
        self.minVoltage = minVoltage
        self.maxVoltage = maxVoltage
        self.voltageDelta = voltageDelta
        self.minTemperature = minTemperature
        self.maxTemperature = maxTemperature
    }

    // MARK: Public

    /// Number of cells in series.
    public let cellCount: Int

    /// Minimum cell voltage in Volts.
    public let minVoltage: Double

    /// Maximum cell voltage in Volts.
    public let maxVoltage: Double

    /// Voltage difference between min and max cells in mV.
    public let voltageDelta: Int

    /// Minimum cell temperature in Celsius.
    public let minTemperature: Double?

    /// Maximum cell temperature in Celsius.
    public let maxTemperature: Double?
}

// MARK: - BMSAlarm

/// BMS alarm type.
public struct BMSAlarm: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    /// Creates a BMS alarm.
    public init(code: Int, description: String, severity: AlarmSeverity = .warning) {
        self.code = code
        self.description = description
        self.severity = severity
    }

    // MARK: Public

    /// Alarm code.
    public let code: Int

    /// Alarm description.
    public let description: String

    /// Alarm severity.
    public let severity: AlarmSeverity
}

// MARK: - AlarmSeverity

/// Alarm severity level.
public enum AlarmSeverity: String, Sendable, Codable {
    /// Informational message.
    case info

    /// Warning (operation continues).
    case warning

    /// Error (operation may be limited).
    case error

    /// Critical (operation stopped).
    case critical
}
