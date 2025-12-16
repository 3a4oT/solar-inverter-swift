# SolarCore

Multi-vendor solar inverter monitoring library for Swift.

[![Swift 6.2+](https://img.shields.io/badge/Swift-6.2+-F05138.svg?logo=swift&logoColor=white)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20|%20iOS%20|%20Linux-lightgrey.svg)](https://swift.org)
[![SPM Compatible](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

## Overview

SolarCore provides a unified API for reading solar inverter data across multiple manufacturers. It uses upstream [ha-solarman](https://github.com/davidrapan/ha-solarman) YAML profiles for register mappings and returns typed Swift models.

**Supported Manufacturers:** Deye, Sofar, Solis, Afore, Kstar, and 13+ more (30 profiles across 18 manufacturers)

> **Note:** Only inverters with Solarman V5 WiFi data loggers are supported. Victron and other manufacturers using proprietary protocols (VE.Direct, VE.Bus) are not compatible.

## Features

- **Multi-Vendor** — 30 profiles across 18 manufacturers
- **ha-solarman Compatible** — Uses upstream YAML profiles directly
- **Type-Safe** — Fully typed Swift models (Codable, Sendable)
- **Swift 6.2** — Typed throws, modern concurrency
- **Full Parsing** — All 10 parsing rules including datetime, bitmasks, sign-magnitude

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/3a4oT/solar-inverter-swift.git", from: "1.0.0")
]
```

Then add to your target:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "SolarCore", package: "solar-inverter-swift"),
    ]
)
```

## Quick Start

### Scoped Driver (CLI / Scripts / Tests)

Auto-closes connection when scope exits. Best for one-off operations:

```swift
import SolarCore

let status = try await withSolarmanDriver(
    host: "192.168.1.100",
    serial: 2712345678,
    profile: .deyeP3,
    groups: [.battery, .pv, .grid]
)
print("SOC: \(status.battery?.soc ?? 0)%")
print("PV Power: \(status.pv?.power ?? 0)W")
```

### Example Output

Real data from a Deye three-phase hybrid inverter (SG0*LP3):

```jsonc
{
  "battery": {
    "current": 0.17,           // A
    "power": 9,                // W (negative = discharging)
    "soc": 95,                 // %
    "temperature": 12,         // °C
    "voltage": 53.28           // V
  },
  "grid": {
    "frequency": 50,           // Hz
    "phases": [
      { "phase": "l1", "power": 148, "voltage": 231.0 },  // W, V
      { "phase": "l2", "power": 262, "voltage": 226.8 },
      { "phase": "l3", "power": 167, "voltage": 224.8 }
    ],
    "power": 577               // W (negative = exporting)
  },
  "inverter": {
    "serial_number": "24XXXXXXXX",
    "status": "standby"
  },
  "load": {
    "phases": [
      { "phase": "l1", "power": 53 },   // W
      { "phase": "l2", "power": 274 },
      { "phase": "l3", "power": 188 }
    ],
    "power": 515               // W
  },
  "pv": {
    "power": 0,                // W
    "strings": [
      { "id": 1, "voltage": 11.6, "current": 0, "power": 0 },  // V, A, W
      { "id": 2, "voltage": 5.0, "current": 0, "power": 0 }
    ]
  },
  "timestamp": "2025-12-14T17:37:28Z"  // UTC
}
```

### Long-Lived Client (Hummingbird / Web Frameworks)

For web services with shared client and graceful shutdown:

```swift
import Hummingbird
import SolarCore
import SolarmanV5

let client = SolarmanV5Client(
    host: "192.168.1.100",
    serial: 2712345678,
    timeout: .seconds(60)
)

let profile = try ProfileLoader().load(.deyeP3)
let driver = SolarmanDriver(client: client)

let router = Router()
router.get("solar/status") { _, _ in
    let status = try await driver.read(profile: profile, groups: [.battery, .pv, .grid])
    return status  // Codable
}

var app = Application(router: router)
app.addServices(client)  // ServiceLifecycle integration
try await app.runService()
```

**Thread Safety:** `SolarmanV5Client` is thread-safe and can be shared across concurrent requests. Internally it uses `Mutex` to serialize Modbus requests — this matches pysolarmanv5 behavior and WiFi logger hardware limitations (most loggers don't support concurrent requests). Concurrent API calls will queue and execute sequentially.

### Custom Groups & JSON Serialization

Read specific sensor groups and serialize to JSON:

```swift
import SolarCore

// Read custom set of groups
let status = try await withSolarmanDriver(
    host: "192.168.1.100",
    serial: 2712345678,
    profile: .deyeP3,
    groups: [.battery, .pv, .load, .inverter]  // Only what you need
)

// Access typed Swift models
if let battery = status.battery {
    print("SOC: \(battery.soc)%")
    print("Power: \(battery.power)W")
}

if let pv = status.pv {
    print("Solar: \(pv.power)W")
    print("Daily: \(pv.dailyProduction ?? 0)kWh")
}

// Serialize to JSON (snake_case, ISO8601 dates, pretty printed)
let jsonData = try SolarStatus.jsonEncoder.encode(status)
let jsonString = String(data: jsonData, encoding: .utf8)!
print(jsonString)
```

**Available groups:** `battery`, `grid`, `pv`, `load`, `inverter`, `generator`, `ups`, `bms`, `timeOfUse`, `alerts`

> **Performance tip:** Request only needed groups. Reading `.battery` alone takes ~100-200ms (1 Modbus request), while all groups take ~1.5-2s (8-10 requests). See [docs/architecture.md](docs/architecture.md) for details.

## Profiles

Profiles use upstream [ha-solarman](https://github.com/davidrapan/ha-solarman) YAML format. For Deye inverters:

| Profile | Models | Type |
|---------|--------|------|
| `deye_hybrid` | SG0*LP1 | Single-phase hybrid |
| `deye_p3` | SG0*LP3, SG0*HP3 | **Three-phase hybrid** |
| `deye_micro` | Microinverter | Micro |
| `deye_string` | G0* | String (grid-tie) |

See [docs/development.md](docs/development.md) for profile sync instructions.

## Architecture

```
SolarCore
├── Models/         Typed data models (Codable, Sendable)
├── Profiles/       ha-solarman YAML profiles
│   ├── Models/     InverterDefinition, SensorItem, ParsingRule
│   ├── Loader/     YAML parsing with security limits
│   └── Resources/  30+ profiles by manufacturer
├── Sensors/        Register → value conversion
│   ├── RegisterBatcher    Optimized Modbus reads (max 125 per request)
│   └── RegisterConverter  Scale, offset, parsing rules
└── Drivers/        Protocol implementations
    └── SolarmanDriver     Solarman V5 (WiFi stick)
```

### Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| [solarman-swift](https://github.com/3a4oT/solarman-swift) | 1.0.0+ | Solarman V5 protocol |
| [Yams](https://github.com/jpsim/Yams) | 6.2.0+ | YAML profile parsing |

## Error Handling

All methods use typed throws for precise error handling:

```swift
do {
    let status = try await withSolarmanDriver(...)
} catch let error as DriverError {
    switch error {
    case .connectionFailed(let message):
        // Network error
    case .profileError(let message):
        // Profile loading failed
    case .timeout:
        // Read timeout
    }
} catch let error as SensorError {
    switch error {
    case .insufficientRegisters(let expected, let got):
        // Not enough data
    case .rawValueOutOfRange(let value, let min, let max):
        // Value filtered by range
    }
}
```

## Development

```bash
# Install SwiftFormat and pre-commit hook
brew install swiftformat
./Scripts/install-hooks.sh

# Run tests
swift test --parallel
```

## Documentation

- [docs/architecture.md](docs/architecture.md) — Package structure, data flow, conversion pipeline
- [docs/energy-calculations.md](docs/energy-calculations.md) — Energy balance, cost calculations, efficiency ratios
- [docs/development.md](docs/development.md) — Setup, testing, profile sync, CI

## References

- [ha-solarman](https://github.com/davidrapan/ha-solarman) — Upstream profiles
- [pysolarmanv5](https://github.com/jmccrohan/pysolarmanv5) — Solarman V5 reference
- [solarman-swift](https://github.com/3a4oT/solarman-swift) — Swift V5 client
- [Deye Modbus Protocol V118](https://github.com/user-attachments/files/16597960/Deye.Modbus.protocol.V118.pdf)

## License

Apache License 2.0. See [LICENSE](LICENSE) for details.
