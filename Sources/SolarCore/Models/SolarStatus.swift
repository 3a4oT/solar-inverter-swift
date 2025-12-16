// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// Date, JSONEncoder/JSONDecoder for timestamps and JSON serialization
#if canImport(FoundationEssentials)
    import FoundationEssentials
#else
    import Foundation
#endif

// MARK: - SolarStatus

/// Complete solar system status snapshot.
///
/// Aggregates all subsystem statuses into a single queryable object.
/// All power values are in Watts, energy in kWh.
///
/// ## Example
///
/// ```swift
/// let status = try await driver.read(profile: profile, groups: [.battery, .pv, .grid])
///
/// // Access subsystems
/// if let battery = status.battery {
///     print("SOC: \(battery.soc)%")
///     print("Power: \(battery.power)W")
/// }
///
/// // JSON output
/// let json = try SolarStatus.jsonEncoder.encode(status)
/// print(String(data: json, encoding: .utf8)!)
/// ```
///
/// ## JSON Format
///
/// ```json
/// {
///   "timestamp": "2025-12-08T14:30:00Z",
///   "battery": {
///     "soc": 85,
///     "voltage": 410.5,
///     "power": 5125
///   },
///   "pv": {
///     "power": 7500,
///     "daily_production": 35.6
///   }
/// }
/// ```
public struct SolarStatus: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    /// Creates a new solar status snapshot.
    ///
    /// - Parameters:
    ///   - timestamp: When this status was captured (defaults to now).
    ///   - battery: Battery subsystem status.
    ///   - grid: Grid connection status.
    ///   - pv: Solar panel production status.
    ///   - load: Load/consumption status.
    ///   - inverter: Inverter device information.
    ///   - generator: Generator input status.
    ///   - ups: UPS output status.
    ///   - bms: BMS detailed status (array for multi-BMS systems).
    ///   - timeOfUse: Time-of-Use schedule.
    ///   - settings: Current inverter settings.
    public init(
        timestamp: Date = Date(),
        battery: BatteryStatus? = nil,
        grid: GridStatus? = nil,
        pv: PVStatus? = nil,
        load: LoadStatus? = nil,
        inverter: InverterInfo? = nil,
        generator: GeneratorStatus? = nil,
        ups: UPSStatus? = nil,
        bms: [BMSStatus]? = nil,
        timeOfUse: TimeOfUseSchedule? = nil,
        settings: InverterSettings? = nil,
    ) {
        self.timestamp = timestamp
        self.battery = battery
        self.grid = grid
        self.pv = pv
        self.load = load
        self.inverter = inverter
        self.generator = generator
        self.ups = ups
        self.bms = bms
        self.timeOfUse = timeOfUse
        self.settings = settings
    }

    // MARK: Public

    /// Timestamp when this status was captured.
    public let timestamp: Date

    // MARK: - Core Subsystems

    /// Battery subsystem status.
    public let battery: BatteryStatus?

    /// Grid connection status.
    public let grid: GridStatus?

    /// Solar panel production status.
    public let pv: PVStatus?

    /// Load/consumption status.
    public let load: LoadStatus?

    /// Inverter device information.
    public let inverter: InverterInfo?

    // MARK: - Extended Subsystems

    /// Generator input status (if available).
    public let generator: GeneratorStatus?

    /// UPS output status (if available).
    public let ups: UPSStatus?

    /// Battery Management System detailed status.
    public let bms: [BMSStatus]?

    /// Time-of-Use schedule configuration.
    public let timeOfUse: TimeOfUseSchedule?

    /// Current inverter settings.
    public let settings: InverterSettings?
}

// MARK: - JSON Encoding

extension SolarStatus {
    /// JSON encoder configured for API output.
    ///
    /// - Uses `snake_case` keys (e.g., `daily_charge`)
    /// - ISO 8601 date format
    /// - Pretty-printed with sorted keys
    public static let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    /// JSON decoder configured for API input.
    ///
    /// - Expects `snake_case` keys
    /// - ISO 8601 date format
    public static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
