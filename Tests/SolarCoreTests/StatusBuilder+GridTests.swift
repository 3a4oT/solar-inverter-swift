// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

@testable import SolarCore
import Testing

// MARK: - Grid StatusBuilder Tests

@Suite("StatusBuilder+Grid")
struct StatusBuilderGridTests {
    let builder = StatusBuilder()

    @Test("Builds grid status with power direction")
    func buildGridPowerDirection() {
        // Importing from grid
        let importValues = SensorValues([
            "grid_power": 1500,
            "grid_voltage": 230.0,
            "grid_frequency": 50.0,
        ])

        let gridImport = builder.buildGrid(from: importValues)

        #expect(gridImport?.power == 1500)
        #expect(gridImport?.frequency == 50.0)
        #expect(gridImport?.phases.first?.voltage == 230.0)

        // Exporting to grid (negative power)
        let exportValues = SensorValues([
            "grid_power": -2000,
            "grid_voltage": 231.0,
        ])

        let gridExport = builder.buildGrid(from: exportValues)

        #expect(gridExport?.power == -2000)
    }

    @Test("Builds all three phases with voltage, current, power")
    func buildGridThreePhase() {
        let values = SensorValues([
            "total_grid_power": 3000,
            "grid_l1_voltage": 230.0,
            "grid_l1_current": 4.5,
            "grid_l1_power": 1000,
            "grid_l2_voltage": 231.0,
            "grid_l2_current": 4.3,
            "grid_l2_power": 1000,
            "grid_l3_voltage": 229.5,
            "grid_l3_current": 4.4,
            "grid_l3_power": 1000,
        ])

        let grid = builder.buildGrid(from: values)

        #expect(grid?.power == 3000)
        #expect(grid?.phases.count == 3)

        let l1 = grid?.phases.first { $0.phase == .l1 }
        #expect(l1?.voltage == 230.0)
        #expect(l1?.current == 4.5)
        #expect(l1?.power == 1000)

        let l2 = grid?.phases.first { $0.phase == .l2 }
        #expect(l2?.voltage == 231.0)
        #expect(l2?.current == 4.3)
        #expect(l2?.power == 1000)

        let l3 = grid?.phases.first { $0.phase == .l3 }
        #expect(l3?.voltage == 229.5)
        #expect(l3?.current == 4.4)
        #expect(l3?.power == 1000)
    }

    @Test("Single-phase fallback when no L1/L2/L3 keys")
    func buildGridSinglePhaseFallback() {
        let values = SensorValues([
            "grid_power": 1500,
            "grid_voltage": 230.0,
            "grid_current": 6.5,
        ])

        let grid = builder.buildGrid(from: values)

        #expect(grid?.phases.count == 1)
        #expect(grid?.phases.first?.phase == .l1)
        #expect(grid?.phases.first?.voltage == 230.0)
        #expect(grid?.phases.first?.current == 6.5)
        #expect(grid?.phases.first?.power == 1500)
    }

    @Test("Partial three-phase (only L1 and L2)")
    func buildGridPartialPhases() {
        let values = SensorValues([
            "grid_power": 2000,
            "grid_l1_voltage": 230.0,
            "grid_l1_power": 1000,
            "grid_l2_voltage": 231.0,
            "grid_l2_power": 1000,
            // No L3
        ])

        let grid = builder.buildGrid(from: values)

        #expect(grid?.phases.count == 2)
    }

    @Test("Uses alternative energy field names")
    func buildGridEnergyAlternatives() {
        let values = SensorValues([
            "grid_power": 500,
            "grid_voltage": 230.0,
            "daily_energy_bought": 15.5, // Alternative for import
            "total_energy_sold": 1200.0, // Alternative for export
        ])

        let grid = builder.buildGrid(from: values)

        #expect(grid?.dailyImport == 15.5)
        #expect(grid?.totalExport == 1200.0)
    }

    // MARK: - ha-solarman Naming (today_* keys)

    @Test("Uses today_energy_import alternative (ha-solarman)")
    func buildGridTodayImport() {
        // ha-solarman: "Today Energy Import" → "today_energy_import"
        let values = SensorValues([
            "grid_power": 500,
            "grid_voltage": 230.0,
            "today_energy_import": 12.3,
        ])

        let grid = builder.buildGrid(from: values)

        #expect(grid?.dailyImport == 12.3)
    }

    @Test("Uses today_energy_export alternative (ha-solarman)")
    func buildGridTodayExport() {
        // ha-solarman: "Today Energy Export" → "today_energy_export"
        let values = SensorValues([
            "grid_power": -1000,
            "grid_voltage": 231.0,
            "today_energy_export": 25.7,
        ])

        let grid = builder.buildGrid(from: values)

        #expect(grid?.dailyExport == 25.7)
    }

    @Test("Uses total_energy_import alternative (ha-solarman)")
    func buildGridTotalImport() {
        // ha-solarman: "Total Energy Import" → "total_energy_import"
        let values = SensorValues([
            "grid_power": 500,
            "grid_voltage": 230.0,
            "total_energy_import": 5432.1,
        ])

        let grid = builder.buildGrid(from: values)

        #expect(grid?.totalImport == 5432.1)
    }

    @Test("Uses total_energy_export alternative (ha-solarman)")
    func buildGridTotalExport() {
        // ha-solarman: "Total Energy Export" → "total_energy_export"
        let values = SensorValues([
            "grid_power": -1000,
            "grid_voltage": 231.0,
            "total_energy_export": 8765.4,
        ])

        let grid = builder.buildGrid(from: values)

        #expect(grid?.totalExport == 8765.4)
    }

    // MARK: - External CT Meter Tests

    @Test("Builds external CT with all three phases")
    func buildExternalCTThreePhase() {
        let values = SensorValues([
            "grid_power": 1000,
            "grid_voltage": 230.0,
            "external_power": 950,
            "external_ct1_power": 300,
            "external_ct1_current": 1.3,
            "external_ct2_power": 320,
            "external_ct2_current": 1.4,
            "external_ct3_power": 330,
            "external_ct3_current": 1.45,
        ])

        let grid = builder.buildGrid(from: values)

        #expect(grid?.externalCT != nil)
        #expect(grid?.externalCT?.power == 950)
        #expect(grid?.externalCT?.phases.count == 3)

        let ct1 = grid?.externalCT?.phases.first { $0.phase == .l1 }
        #expect(ct1?.power == 300)
        #expect(ct1?.current == 1.3)

        let ct2 = grid?.externalCT?.phases.first { $0.phase == .l2 }
        #expect(ct2?.power == 320)
        #expect(ct2?.current == 1.4)

        let ct3 = grid?.externalCT?.phases.first { $0.phase == .l3 }
        #expect(ct3?.power == 330)
        #expect(ct3?.current == 1.45)
    }

    @Test("External CT nil when no external data")
    func buildExternalCTNil() {
        let values = SensorValues([
            "grid_power": 1000,
            "grid_voltage": 230.0,
            // No external_* keys
        ])

        let grid = builder.buildGrid(from: values)

        #expect(grid?.externalCT == nil)
    }

    @Test("External CT sums phases when total not available")
    func buildExternalCTSumPhases() {
        let values = SensorValues([
            "grid_power": 1000,
            "grid_voltage": 230.0,
            // No external_power, only per-phase
            "external_ct1_power": 100,
            "external_ct2_power": 200,
            "external_ct3_power": 300,
        ])

        let grid = builder.buildGrid(from: values)

        #expect(grid?.externalCT?.power == 600) // 100 + 200 + 300
    }

    @Test("External CT partial phases")
    func buildExternalCTPartialPhases() {
        let values = SensorValues([
            "grid_power": 500,
            "grid_voltage": 230.0,
            "external_ct1_power": 250,
            // Only L1, no L2/L3
        ])

        let grid = builder.buildGrid(from: values)

        #expect(grid?.externalCT?.phases.count == 1)
        #expect(grid?.externalCT?.phases.first?.phase == .l1)
        #expect(grid?.externalCT?.power == 250)
    }

    @Test("External CT negative power (export)")
    func buildExternalCTNegativePower() {
        let values = SensorValues([
            "grid_power": -2000,
            "grid_voltage": 231.0,
            "external_power": -1950,
            "external_ct1_power": -650,
            "external_ct2_power": -650,
            "external_ct3_power": -650,
        ])

        let grid = builder.buildGrid(from: values)

        #expect(grid?.externalCT?.power == -1950)
        #expect(grid?.externalCT?.phases.first?.power == -650)
    }
}
