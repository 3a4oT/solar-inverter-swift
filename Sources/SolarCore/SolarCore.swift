// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - SolarCore

@_exported import SolarmanV5

/// Multi-vendor solar inverter monitoring library.
///
/// SolarCore provides:
/// - **Data Models** — Typed Swift structs for solar system status
/// - **Sensor Abstraction** — Register-to-value conversion layer
/// - **Inverter Profiles** — YAML-based device definitions (ha-solarman format)
/// - **Protocol Driver** — Solarman V5 via WiFi data logging sticks
///
/// ## Quick Start
///
/// ```swift
/// import SolarCore
///
/// // One-off read with automatic connection management
/// let status = try await withSolarmanDriver(
///     host: "192.168.1.100",
///     serial: 2712345678,
///     profile: .deyeP3,
///     groups: [.battery, .pv, .grid]
/// )
///
/// // Access typed data
/// print("Battery SOC: \(status.battery?.soc ?? 0)%")
/// print("PV Power: \(status.pv?.power ?? 0)W")
/// ```
///
/// ## Architecture
///
/// ```
/// ┌─────────────────────────────────────────┐
/// │  Application (CLI, Widget)              │
/// ├─────────────────────────────────────────┤
/// │  SolarCore                              │
/// │  ├── Models/      Data models           │
/// │  ├── Sensors/     Register abstraction  │
/// │  ├── Profiles/    YAML definitions      │
/// │  └── Drivers/     SolarmanV5 driver     │
/// ├─────────────────────────────────────────┤
/// │  SolarmanV5 (solarman-swift)            │
/// └─────────────────────────────────────────┘
/// ```
///
/// ## References
///
/// - [ha-solarman](https://github.com/davidrapan/ha-solarman) — Upstream profiles
/// - [pysolarmanv5](https://github.com/jmccrohan/pysolarmanv5) — Solarman V5 reference
/// - [Deye Modbus Protocol](https://github.com/user-attachments/files/16597960/Deye.Modbus.protocol.V118.pdf)
public enum SolarCore {}
