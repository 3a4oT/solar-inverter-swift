# Energy Calculations Guide

This guide explains how to calculate derived metrics from SolarCore data for energy management applications.

## Energy Balance Fundamentals

### Instantaneous Power Balance

At any moment, energy must be conserved:

```
Sources = Sinks + Losses

PV + GridImport + BatteryDischarge + Generator =
    GridExport + BatteryCharge + Load + InverterLosses
```

Typical inverter losses: 2-5% of throughput.

### Power Flow Diagram

```
                         ┌─────────────────────────────────────┐
                         │           GRID METER                │
                         │    (externalCT if installed)        │
                         └──────────────┬──────────────────────┘
                                        │
            ┌───────────────────────────┼───────────────────────┐
            │                           │                       │
            ▼                           ▼                       ▼
    ┌───────────────┐           ┌───────────────┐       ┌───────────────┐
    │  BYPASS LOAD  │           │   INVERTER    │       │  BYPASS LOAD  │
    │   (direct)    │           │               │       │   (direct)    │
    │               │           │  grid.power   │       │               │
    │  e.g. AC unit │           │  load.power   │       │  e.g. boiler  │
    └───────────────┘           │  pv.power     │       └───────────────┘
           ▲                    │  battery      │              ▲
           │                    └───────┬───────┘              │
           │                            │                      │
           │              ┌─────────────┼─────────────┐        │
           │              ▼             ▼             ▼        │
           │        ┌──────────┐  ┌──────────┐  ┌──────────┐   │
           │        │   PV     │  │ BATTERY  │  │INVERTER  │   │
           │        │  Array   │  │          │  │  LOAD    │   │
           │        └──────────┘  └──────────┘  └──────────┘   │
           │                                                   │
           └───────────────── NOT VISIBLE ─────────────────────┘
                              TO INVERTER
                        (unless External CT installed)
```

### What Inverter Sees vs Reality

| Metric | Without External CT | With External CT |
|--------|---------------------|------------------|
| Grid power | Inverter connection only | Total household |
| Bypass loads | **Invisible** | Calculated |
| Total consumption | Underestimated | Accurate |

## Sign Conventions

SolarCore uses consistent sign conventions across all models:

| Measurement | Positive | Negative |
|-------------|----------|----------|
| `grid.power` | Importing (buying) | Exporting (selling) |
| `battery.power` | Charging | Discharging |
| `load.power` | Always positive | N/A |
| `pv.power` | Always positive | N/A |
| `externalCT.power` | Importing | Exporting |

## Common Calculations

### Bypass Load (requires External CT)

Loads connected directly to grid, bypassing the inverter:

```swift
extension SolarStatus {
    /// Power flowing to loads that bypass the inverter.
    /// Requires External CT/Smart Meter to be installed.
    /// Returns nil if no External CT data available.
    var bypassPower: Int? {
        guard let ctPower = grid?.externalCT?.power,
              let inverterGridPower = grid?.power else {
            return nil
        }
        // CT sees total, inverter sees its portion
        // Difference is bypass (can be negative if CT < inverter due to timing)
        return ctPower - inverterGridPower
    }

    /// Total household power consumption.
    /// Includes both inverter load and bypass loads.
    var totalHouseholdPower: Int? {
        guard let inverterLoad = load?.power else { return nil }

        // If we have bypass data, add it (only positive values)
        if let bypass = bypassPower {
            return inverterLoad + max(0, bypass)
        }

        // Without External CT, we only know inverter load
        return inverterLoad
    }
}
```

### Power Sources & Sinks

Decompose power flow into clear categories:

```swift
extension SolarStatus {
    // MARK: - Power Sources

    /// Solar production (always >= 0).
    var solarPower: Int { pv?.power ?? 0 }

    /// Power imported from grid (>= 0).
    var gridImportPower: Int { max(0, grid?.power ?? 0) }

    /// Power discharged from battery (>= 0).
    var batteryDischargePower: Int { max(0, -(battery?.power ?? 0)) }

    /// Generator power (>= 0).
    var generatorPowerValue: Int { generator?.power ?? 0 }

    /// Total power from all sources.
    var totalSourcePower: Int {
        solarPower + gridImportPower + batteryDischargePower + generatorPowerValue
    }

    // MARK: - Power Sinks

    /// Power exported to grid (>= 0).
    var gridExportPower: Int { max(0, -(grid?.power ?? 0)) }

    /// Power charging battery (>= 0).
    var batteryChargePower: Int { max(0, battery?.power ?? 0) }

    /// Load power through inverter (>= 0).
    var inverterLoadPower: Int { load?.power ?? 0 }

    /// Total power to all sinks (excluding losses).
    var totalSinkPower: Int {
        gridExportPower + batteryChargePower + inverterLoadPower + (bypassPower ?? 0)
    }
}
```

### Self-Consumption Ratio

How much of your production is consumed locally vs exported:

```swift
extension SolarStatus {
    /// Self-consumption ratio as percentage (0-100).
    ///
    /// Formula: (Production - Export) / Production * 100
    ///
    /// - 100% = All production consumed locally
    /// - 0% = All production exported
    /// - Returns nil if no production
    var selfConsumptionRatio: Double? {
        let production = solarPower + generatorPowerValue
        guard production > 0 else { return nil }

        let consumed = production - gridExportPower
        return Double(max(0, consumed)) / Double(production) * 100
    }
}
```

### Self-Sufficiency Ratio

How independent you are from the grid:

```swift
extension SolarStatus {
    /// Self-sufficiency ratio as percentage (0-100).
    ///
    /// Formula: (Consumption - Import) / Consumption * 100
    ///
    /// - 100% = Fully independent from grid
    /// - 0% = Fully dependent on grid
    /// - Returns nil if no consumption
    var selfSufficiencyRatio: Double? {
        let consumption = totalHouseholdPower ?? inverterLoadPower
        guard consumption > 0 else { return nil }

        let fromOwnSources = consumption - gridImportPower
        return Double(max(0, fromOwnSources)) / Double(consumption) * 100
    }
}
```

## Daily Energy & Cost Calculations

### Daily Energy Summary

```swift
struct DailyEnergySummary {
    // From SolarStatus
    let production: Double      // pv.dailyProduction (kWh)
    let gridImport: Double      // grid.dailyImport (kWh)
    let gridExport: Double      // grid.dailyExport (kWh)
    let consumption: Double     // load.dailyConsumption (kWh)
    let batteryCharge: Double   // battery.dailyCharge (kWh)
    let batteryDischarge: Double // battery.dailyDischarge (kWh)

    /// Net grid energy (positive = net import, negative = net export).
    var netGrid: Double {
        gridImport - gridExport
    }

    /// Energy consumed from own production.
    var selfConsumed: Double {
        min(production, consumption)
    }

    /// Daily self-consumption ratio.
    var selfConsumptionRatio: Double {
        guard production > 0 else { return 0 }
        return selfConsumed / production * 100
    }

    /// Daily self-sufficiency ratio.
    var selfSufficiencyRatio: Double {
        guard consumption > 0 else { return 100 }
        return (consumption - gridImport) / consumption * 100
    }
}

extension SolarStatus {
    var dailyEnergySummary: DailyEnergySummary? {
        DailyEnergySummary(
            production: pv?.dailyProduction ?? 0,
            gridImport: grid?.dailyImport ?? 0,
            gridExport: grid?.dailyExport ?? 0,
            consumption: load?.dailyConsumption ?? 0,
            batteryCharge: battery?.dailyCharge ?? 0,
            batteryDischarge: battery?.dailyDischarge ?? 0
        )
    }
}
```

### Cost Calculations

```swift
struct EnergyTariff {
    /// Import price per kWh (what you pay).
    let importPrice: Double

    /// Export price per kWh (what you receive, feed-in tariff).
    let exportPrice: Double

    /// Currency code (e.g., "UAH", "EUR").
    let currency: String
}

struct DailyCostAnalysis {
    let summary: DailyEnergySummary
    let tariff: EnergyTariff

    /// Cost of imported energy.
    var importCost: Double {
        summary.gridImport * tariff.importPrice
    }

    /// Revenue from exported energy.
    var exportRevenue: Double {
        summary.gridExport * tariff.exportPrice
    }

    /// Net cost (positive = expense, negative = income).
    var netCost: Double {
        importCost - exportRevenue
    }

    /// Savings from self-consumption vs buying from grid.
    /// What you would have paid if you bought self-consumed energy.
    var selfConsumptionSavings: Double {
        summary.selfConsumed * tariff.importPrice
    }

    /// Total benefit = savings + export revenue.
    var totalBenefit: Double {
        selfConsumptionSavings + exportRevenue
    }

    /// Formatted summary.
    var description: String {
        """
        Daily Cost Analysis (\(tariff.currency)):
        ├─ Import cost:      \(String(format: "%.2f", importCost))
        ├─ Export revenue:   \(String(format: "%.2f", exportRevenue))
        ├─ Net cost:         \(String(format: "%.2f", netCost))
        ├─ Self-consumption: \(String(format: "%.2f", selfConsumptionSavings)) saved
        └─ Total benefit:    \(String(format: "%.2f", totalBenefit))
        """
    }
}

// Usage example
let tariff = EnergyTariff(
    importPrice: 4.32,   // UAH/kWh
    exportPrice: 3.50,   // UAH/kWh (green tariff)
    currency: "UAH"
)

if let summary = status.dailyEnergySummary {
    let analysis = DailyCostAnalysis(summary: summary, tariff: tariff)
    print(analysis.description)
}
```

### Time-of-Use (TOU) Cost Calculation

For variable tariffs based on time of day:

```swift
struct TOUTariff {
    struct Period {
        let name: String           // "Peak", "Off-Peak", "Night"
        let startHour: Int         // 0-23
        let endHour: Int           // 0-23
        let importPrice: Double
        let exportPrice: Double
    }

    let periods: [Period]
    let currency: String

    func price(at hour: Int, isExport: Bool) -> Double {
        let period = periods.first { p in
            if p.startHour <= p.endHour {
                return hour >= p.startHour && hour < p.endHour
            } else {
                // Overnight period (e.g., 23:00 - 07:00)
                return hour >= p.startHour || hour < p.endHour
            }
        }
        return isExport ? (period?.exportPrice ?? 0) : (period?.importPrice ?? 0)
    }
}

// Example: Ukraine 3-zone tariff
let ukraineTOU = TOUTariff(
    periods: [
        .init(name: "Night",    startHour: 23, endHour: 7,  importPrice: 2.16, exportPrice: 1.75),
        .init(name: "Half-Peak", startHour: 7, endHour: 8,  importPrice: 3.24, exportPrice: 2.62),
        .init(name: "Half-Peak", startHour: 10, endHour: 17, importPrice: 3.24, exportPrice: 2.62),
        .init(name: "Half-Peak", startHour: 21, endHour: 23, importPrice: 3.24, exportPrice: 2.62),
        .init(name: "Peak",     startHour: 8, endHour: 10, importPrice: 4.32, exportPrice: 3.50),
        .init(name: "Peak",     startHour: 17, endHour: 21, importPrice: 4.32, exportPrice: 3.50),
    ],
    currency: "UAH"
)
```

## Battery Calculations

### Time Remaining Estimate

```swift
extension SolarStatus {
    /// Estimated battery time remaining at current discharge rate.
    /// Returns nil if battery not discharging or data unavailable.
    func batteryTimeRemaining(capacityWh: Double) -> TimeInterval? {
        guard let soc = battery?.soc,
              let power = battery?.power,
              power < -50  // Discharging at least 50W
        else { return nil }

        let remainingWh = capacityWh * Double(soc) / 100
        let dischargeW = Double(-power)

        // Time in seconds
        return (remainingWh / dischargeW) * 3600
    }

    /// Estimated time to full charge at current rate.
    /// Returns nil if battery not charging or data unavailable.
    func batteryTimeToFull(capacityWh: Double) -> TimeInterval? {
        guard let soc = battery?.soc,
              let power = battery?.power,
              power > 50  // Charging at least 50W
        else { return nil }

        let remainingWh = capacityWh * Double(100 - soc) / 100
        let chargeW = Double(power)

        return (remainingWh / chargeW) * 3600
    }
}

// Usage
let capacityWh = 10000.0  // 10kWh battery

if let remaining = status.batteryTimeRemaining(capacityWh: capacityWh) {
    let hours = remaining / 3600
    print("Battery remaining: \(String(format: "%.1f", hours)) hours")
}
```

### Battery Cycles

```swift
extension SolarStatus {
    /// Estimated battery cycles from total charge energy.
    ///
    /// One cycle = one full discharge equivalent.
    /// For example, 2x 50% discharges = 1 cycle.
    func batteryLifeCycles(capacityKWh: Double) -> Double? {
        guard let totalDischarge = battery?.totalDischarge,
              capacityKWh > 0 else { return nil }

        return totalDischarge / capacityKWh
    }
}
```

## Edge Cases & Gotchas

### 1. Timing Differences

Power readings are instantaneous snapshots. Grid import and export can both be non-zero in the same reading if:
- Values averaged over different windows
- Rapid changes during measurement

**Solution:** Use energy counters (kWh) for accurate daily totals, not integrated power.

### 2. Negative Bypass Load

If `bypassPower` is negative, it usually means:
- Timing mismatch between CT and inverter readings
- Measurement errors

**Solution:** Clamp to zero or filter small negative values:
```swift
let bypassLoad = max(0, ctPower - inverterGridPower)
```

### 3. Missing External CT

Many installations don't have external meters. Without it:
- Bypass loads are invisible
- `totalHouseholdPower` equals `inverterLoadPower`
- Self-sufficiency may be overestimated

**Solution:** Document this limitation in your app UI.

### 4. Three-Phase Imbalance

In three-phase systems, phases can have very different loads. Total power hides this:

```swift
extension GridStatus {
    /// Maximum phase power imbalance as percentage.
    var phaseImbalance: Double? {
        guard phases.count == 3,
              let powers = phases.compactMap(\.power) as? [Int],
              powers.count == 3 else { return nil }

        let avg = Double(powers.reduce(0, +)) / 3
        guard avg > 0 else { return nil }

        let maxDev = powers.map { abs(Double($0) - avg) }.max() ?? 0
        return maxDev / avg * 100
    }
}
```

### 5. Battery Power vs Energy

Power (W) is instantaneous; energy (kWh) is accumulated:
- `battery.power = 1000W` doesn't mean 1kWh used
- Check `dailyCharge`/`dailyDischarge` for actual energy

### 6. Zero Division

Always guard against zero denominators:

```swift
// Bad
let ratio = consumption / production  // Crash if production = 0

// Good
let ratio = production > 0 ? consumption / production : 0
```

## Energy Balance Validation

Use this to detect measurement issues:

```swift
extension SolarStatus {
    /// Energy balance error as percentage.
    /// Should be close to 0% (typically 2-5% due to inverter losses).
    /// Large values indicate measurement problems.
    var energyBalanceError: Double? {
        let sources = Double(solarPower + gridImportPower + batteryDischargePower + generatorPowerValue)
        let sinks = Double(gridExportPower + batteryChargePower + inverterLoadPower)

        guard sources > 100 || sinks > 100 else { return nil }  // Need meaningful power

        let total = max(sources, sinks)
        return abs(sources - sinks) / total * 100
    }
}

// Usage: Alert if balance error > 10%
if let error = status.energyBalanceError, error > 10 {
    print("Warning: Energy balance error \(error)% - check sensors")
}
```

## Summary

| Calculation | Requires | Accuracy |
|-------------|----------|----------|
| Inverter load | `load.power` | High |
| Bypass load | External CT | High |
| Total household | External CT | Medium without CT |
| Self-consumption | `pv`, `grid` | High |
| Self-sufficiency | `load`, `grid` | Medium without CT |
| Daily costs | Energy counters | High |
| Battery time | Power + capacity | Estimate |

## References

- [docs/architecture.md](architecture.md) — Data model and sign conventions
- [ha-solarman](https://github.com/davidrapan/ha-solarman) — Upstream profile definitions
