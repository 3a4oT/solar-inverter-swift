# Architecture

SolarCore reads Modbus registers via Solarman V5 protocol and converts them into typed Swift models for solar inverter monitoring.

## Overview

```
┌─────────────────┐     ┌─────────────────┐
│  solarman-swift │     │      Yams       │
│   (V5 Protocol) │     │  (YAML Parser)  │
└────────┬────────┘     └────────┬────────┘
         │                       │
         └───────────┬───────────┘
                     ▼
              ┌─────────────┐
              │  SolarCore  │
              └─────────────┘
```

## Data Flow

```
Profile (YAML) → Register Batching → Modbus Read → Value Conversion → Status Model
```

1. **Profile Loading** — Parse ha-solarman YAML into `InverterDefinition`
2. **Register Batching** — Optimize reads (max 125 registers per request)
3. **Modbus Communication** — Read via Solarman V5 WiFi stick
4. **Value Conversion** — Apply parsing rules, scale, offset, validation
5. **Status Building** — Map sensor values to typed Swift models

## Selective Reading & Performance

The driver supports **selective group reading** for optimal performance. You can request one group, multiple groups, or all groups at once.

### Sensor Groups

| Group | Description | Typical Registers |
|-------|-------------|-------------------|
| `battery` | SOC, voltage, current, power, energy | ~15 |
| `grid` | Power, frequency, phases, import/export | ~25 |
| `pv` | Solar production, strings | ~20 |
| `load` | Consumption, phases | ~15 |
| `inverter` | Status, temperature, alarms, faults | ~30 |
| `generator` | Generator input metrics | ~10 |
| `ups` | UPS/EPS output metrics | ~15 |
| `bms` | Battery management details | ~40 |
| `timeOfUse` | TOU schedule configuration | ~50 |
| `settings` | Writable inverter settings | ~30 |
| `alerts` | Alert and fault sensors | ~10 |
| `computed` | Computed/derived sensors | 0 (no registers) |

### Usage Examples

```swift
// Single group — fastest (1 Modbus request, ~100-200ms)
let status = try await driver.read(profile: profile, groups: [.battery])

// Multiple groups
let status = try await driver.read(profile: profile, groups: [.battery, .pv, .grid])

// Basic monitoring (default when empty)
let status = try await driver.read(profile: profile, groups: [])
// Equivalent to: [.battery, .grid, .pv, .load]

// Full read — all available data
let status = try await driver.read(profile: profile, groups: Set(SensorGroup.allCases))
```

### Performance Impact

| Scenario | Groups | Registers | Modbus Requests | Latency |
|----------|--------|-----------|-----------------|---------|
| Widget (SOC only) | `battery` | ~15 | 1 | ~100-200ms |
| Basic monitoring | `basic` (4 groups) | ~75 | 2-3 | ~300-500ms |
| Dashboard | 6-7 groups | ~150 | 5-6 | ~800ms-1s |
| Full diagnostic | all groups | ~220 | 8-10 | ~1.5-2s |

### How Batching Works

1. **Collect sensors** — Only sensors from requested groups
2. **Sort by address** — Group nearby registers
3. **Create batches** — Max 125 registers per Modbus request (protocol limit)
4. **Merge gaps** — Adjacent registers (gap ≤ 10) read in single request

```
Registers: [100, 101, 102, 150, 151, 500, 501]
           └──────┬──────┘  └──┬──┘  └──┬──┘
              Batch 1       Batch 1   Batch 2
              (gap=48)      (merged)  (gap=349)
```

### Best Practices

- **Widgets**: Use `[.battery]` for SOC display — single request
- **Live monitoring**: Use `[.battery, .pv, .grid, .load]` — basic metrics
- **Diagnostics**: Add `.inverter`, `.bms` only when needed
- **Avoid polling all groups** — unnecessary network load

## Package Structure

```
Sources/SolarCore/
├── Models/          # Domain models (BatteryStatus, GridStatus, etc.)
├── Profiles/        # ha-solarman YAML loading and registry
├── Sensors/         # Register batching and value conversion
└── Drivers/         # Protocol implementation and status building
```

## Output Model

```swift
struct SolarStatus: Codable, Sendable {
    let timestamp: Date
    let battery: BatteryStatus?
    let pv: PVStatus?
    let grid: GridStatus?
    let load: LoadStatus?
    let inverter: InverterInfo?
    let generator: GeneratorStatus?
    let ups: UPSStatus?
    let bms: [BMSStatus]?
}
```

All values use SI units (W, V, A, kWh). No formatting or localization.

**Power sign convention:**
- Positive = charging / importing
- Negative = discharging / exporting

## Energy Meters

Built-in hardware counters track cumulative energy (kWh).

### Daily (reset at midnight)

| Model | Field | Description |
|-------|-------|-------------|
| Battery | `dailyCharge` | Energy charged into battery |
| Battery | `dailyDischarge` | Energy discharged from battery |
| Grid | `dailyImport` | Energy bought from grid |
| Grid | `dailyExport` | Energy sold to grid |
| PV | `dailyProduction` | Solar energy produced |
| Load | `dailyConsumption` | Energy consumed |

### Lifetime (cumulative)

| Model | Field | Description |
|-------|-------|-------------|
| Battery | `totalCharge`, `totalDischarge` | Lifetime battery throughput |
| Grid | `totalImport`, `totalExport` | Lifetime grid exchange |
| PV | `totalProduction` | Lifetime solar production |
| Load | `totalConsumption` | Lifetime consumption |

### Energy Balance

```
Consumption ≈ Import + Production + Discharge - Export - Charge
```

## Sensor Name Normalization

Profile sensor names normalize to snake_case:
- `"Battery SOC"` → `battery_soc`
- `"Grid L1 Power"` → `grid_l1_power`

Cross-profile alternative keys are supported:

| Field | Primary | Alternatives |
|-------|---------|--------------|
| Daily Import | `daily_energy_import` | `today_energy_import` |
| Daily Export | `daily_energy_export` | `today_energy_export` |
| Daily Production | `daily_production` | `today_production` |
| Daily Consumption | `daily_consumption` | `today_load_consumption` |

## Parsing Rules

| Rule | Type | Description |
|------|------|-------------|
| 1 | UInt16 | Unsigned 16-bit |
| 2 | Int16 | Signed 16-bit |
| 3 | UInt32 | Unsigned 32-bit (CDAB) |
| 4 | Int32 | Signed 32-bit |
| 5 | ASCII | UTF-8 string |
| 6 | Bits | Status flags |
| 7 | Version | Firmware (nibbles) |
| 8 | DateTime | RTC timestamp |
| 9 | Time | HHMM format |

## Profile Format

Uses upstream [ha-solarman](https://github.com/davidrapan/ha-solarman) YAML:

```yaml
info:
  manufacturer: Deye
  model: SG0*LP3

parameters:
  - group: Battery
    items:
      - name: "Battery SOC"
        rule: 1
        registers: [0x00B8]
        uom: "%"
```

## Sample Output

```json
{
  "timestamp": "2025-12-14T18:32:25Z",
  "battery": {
    "soc": 95,
    "voltage": 53.29,
    "power": 8,
    "daily_charge": 0.4,
    "daily_discharge": 0.8,
    "total_charge": 297.3,
    "total_discharge": 364.5
  },
  "pv": {
    "power": 0,
    "daily_production": 1.9,
    "total_production": 9256.6,
    "strings": [
      { "id": 1, "voltage": 10.8, "current": 0, "power": 0 },
      { "id": 2, "voltage": 7.2, "current": 0, "power": 0 }
    ]
  },
  "grid": {
    "power": 12183,
    "frequency": 49.95,
    "daily_import": 60.1,
    "daily_export": 0.2,
    "total_import": 4613,
    "total_export": 7198,
    "phases": [
      { "phase": "l1", "voltage": 228.2, "power": 4061 },
      { "phase": "l2", "voltage": 227.9, "power": 4121 },
      { "phase": "l3", "voltage": 223.4, "power": 4001 }
    ]
  },
  "load": {
    "power": 12122,
    "daily_consumption": 60.9,
    "total_consumption": 6213.7,
    "phases": [
      { "phase": "l1", "power": 3969 },
      { "phase": "l2", "power": 4143 },
      { "phase": "l3", "power": 4010 }
    ]
  },
  "inverter": {
    "serial_number": "2408147466",
    "status": "running",
    "dc_temperature": 25
  },
  "bms": [{
    "unit": 1,
    "is_connected": true,
    "soc": 95,
    "voltage": 53.2,
    "charging_voltage": 58.4
  }],
  "ups": {
    "power": 461,
    "phases": [
      { "phase": "l1", "power": 16 },
      { "phase": "l2", "power": 259 },
      { "phase": "l3", "power": 186 }
    ]
  },
  "generator": {
    "power": 0,
    "daily_production": 0
  }
}
```

## References

- [ha-solarman](https://github.com/davidrapan/ha-solarman) — Upstream YAML profiles
- [solarman-swift](https://github.com/3a4oT/solarman-swift) — Solarman V5 protocol
- [Deye Modbus Protocol](https://github.com/user-attachments/files/16597960/Deye.Modbus.protocol.V118.pdf)
