// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - InverterSettings

/// Inverter configuration settings (writable).
///
/// These settings can be read and written to configure inverter behavior.
/// Changes take effect immediately or after inverter restart depending on setting.
public struct InverterSettings: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    /// Creates inverter settings.
    public init(
        power: PowerSettings? = nil,
        battery: BatterySettings? = nil,
        grid: GridSettings? = nil,
        workMode: WorkMode? = nil,
    ) {
        self.power = power
        self.battery = battery
        self.grid = grid
        self.workMode = workMode
    }

    // MARK: Public

    /// Power management settings.
    public let power: PowerSettings?

    /// Battery configuration.
    public let battery: BatterySettings?

    /// Grid configuration.
    public let grid: GridSettings?

    /// Work mode selection.
    public let workMode: WorkMode?
}

// MARK: - PowerSettings

/// Power management settings.
public struct PowerSettings: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    /// Creates power settings.
    public init(
        maxSolarPower: Int? = nil,
        maxSellPower: Int? = nil,
        solarExportEnabled: Bool? = nil,
        loadLimitEnabled: Bool? = nil,
        loadLimitPower: Int? = nil,
        peakShavingEnabled: Bool? = nil,
        peakShavingPower: Int? = nil,
    ) {
        self.maxSolarPower = maxSolarPower
        self.maxSellPower = maxSellPower
        self.solarExportEnabled = solarExportEnabled
        self.loadLimitEnabled = loadLimitEnabled
        self.loadLimitPower = loadLimitPower
        self.peakShavingEnabled = peakShavingEnabled
        self.peakShavingPower = peakShavingPower
    }

    // MARK: Public

    /// Maximum solar power in Watts.
    public let maxSolarPower: Int?

    /// Maximum sell (export) power in Watts.
    public let maxSellPower: Int?

    /// Solar export control enabled.
    public let solarExportEnabled: Bool?

    /// Load limit enabled.
    public let loadLimitEnabled: Bool?

    /// Load limit power in Watts.
    public let loadLimitPower: Int?

    /// Peak shaving enabled.
    public let peakShavingEnabled: Bool?

    /// Peak shaving power limit in Watts.
    public let peakShavingPower: Int?
}

// MARK: - BatterySettings

/// Battery configuration settings.
public struct BatterySettings: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    /// Creates battery settings.
    public init(
        shutdownSOC: Int? = nil,
        lowSOC: Int? = nil,
        restartSOC: Int? = nil,
        shutdownVoltage: Double? = nil,
        lowVoltage: Double? = nil,
        restartVoltage: Double? = nil,
        maxChargeCurrent: Double? = nil,
        maxDischargeCurrent: Double? = nil,
        gridChargeCurrent: Double? = nil,
        equalizationVoltage: Double? = nil,
        absorptionVoltage: Double? = nil,
        floatVoltage: Double? = nil,
        capacity: Int? = nil,
        bmsProtocol: BMSProtocol? = nil,
    ) {
        self.shutdownSOC = shutdownSOC
        self.lowSOC = lowSOC
        self.restartSOC = restartSOC
        self.shutdownVoltage = shutdownVoltage
        self.lowVoltage = lowVoltage
        self.restartVoltage = restartVoltage
        self.maxChargeCurrent = maxChargeCurrent
        self.maxDischargeCurrent = maxDischargeCurrent
        self.gridChargeCurrent = gridChargeCurrent
        self.equalizationVoltage = equalizationVoltage
        self.absorptionVoltage = absorptionVoltage
        self.floatVoltage = floatVoltage
        self.capacity = capacity
        self.bmsProtocol = bmsProtocol
    }

    // MARK: Public

    /// Shutdown SOC percentage (system stops at this level).
    public let shutdownSOC: Int?

    /// Low SOC warning percentage.
    public let lowSOC: Int?

    /// Restart SOC percentage (after shutdown).
    public let restartSOC: Int?

    /// Shutdown voltage in Volts.
    public let shutdownVoltage: Double?

    /// Low voltage warning in Volts.
    public let lowVoltage: Double?

    /// Restart voltage in Volts.
    public let restartVoltage: Double?

    /// Maximum charge current in Amps.
    public let maxChargeCurrent: Double?

    /// Maximum discharge current in Amps.
    public let maxDischargeCurrent: Double?

    /// Grid charge current in Amps.
    public let gridChargeCurrent: Double?

    /// Equalization voltage in Volts.
    public let equalizationVoltage: Double?

    /// Absorption voltage in Volts.
    public let absorptionVoltage: Double?

    /// Float voltage in Volts.
    public let floatVoltage: Double?

    /// Battery capacity in Ah.
    public let capacity: Int?

    /// BMS protocol type.
    public let bmsProtocol: BMSProtocol?
}

// MARK: - BMSProtocol

/// BMS communication protocol.
public enum BMSProtocol: String, Sendable, Codable {
    case none
    case pace
    case pylon
    case pylonH
    case soltaro
    case byd
    case weco
    case solis
    case dyness
    case custom
}

// MARK: - GridSettings

/// Grid configuration settings.
public struct GridSettings: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    /// Creates grid settings.
    public init(
        gridChargeEnabled: Bool? = nil,
        gridAlwaysOn: Bool? = nil,
        generatorChargeEnabled: Bool? = nil,
        generatorPeakShaving: Bool? = nil,
        exportLimit: Int? = nil,
    ) {
        self.gridChargeEnabled = gridChargeEnabled
        self.gridAlwaysOn = gridAlwaysOn
        self.generatorChargeEnabled = generatorChargeEnabled
        self.generatorPeakShaving = generatorPeakShaving
        self.exportLimit = exportLimit
    }

    // MARK: Public

    /// Grid charge enabled.
    public let gridChargeEnabled: Bool?

    /// Grid always on (never disconnect).
    public let gridAlwaysOn: Bool?

    /// Generator charge enabled.
    public let generatorChargeEnabled: Bool?

    /// Generator peak shaving enabled.
    public let generatorPeakShaving: Bool?

    /// Export limit in Watts (0 = no export).
    public let exportLimit: Int?
}

// MARK: - WorkMode

/// Inverter work mode.
public enum WorkMode: String, Sendable, Codable {
    /// Selling first (export excess to grid).
    case sellingFirst

    /// Zero export (no grid feed-in).
    case zeroExport

    /// Battery first (charge battery before export).
    case batteryFirst

    /// Load first (power load before charging).
    case loadFirst

    /// Generator mode.
    case generator

    /// Peak shaving mode.
    case peakShaving

    /// Standby (minimal operation).
    case standby
}
