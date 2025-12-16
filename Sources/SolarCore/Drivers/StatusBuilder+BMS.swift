// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

extension StatusBuilder {
    // MARK: Internal

    /// Build `BMSStatus` array from extracted values.
    /// Returns array because some systems have multiple BMS units (BMS1, BMS2).
    func buildBMS(from values: SensorValues) -> [BMSStatus]? {
        guard !values.isEmpty else {
            return nil
        }

        var bmsUnits: [BMSStatus] = []

        // Try Battery 1 first (deye_p3 style: "Battery 1 SOH" → "battery_1_soh")
        if let bms1 = buildBMSUnit(from: values, unit: 1, prefix: "battery_1") {
            bmsUnits.append(bms1)
        }

        // Try Battery 2 if available
        if let bms2 = buildBMSUnit(from: values, unit: 2, prefix: "battery_2") {
            bmsUnits.append(bms2)
        }

        // Fallback to generic BMS data (deye_hybrid style: "Battery BMS SOC" → "battery_bms_soc")
        if bmsUnits.isEmpty, let bms = buildBMSUnit(from: values, unit: 1, prefix: "battery_bms") {
            bmsUnits.append(bms)
        }

        return bmsUnits.isEmpty ? nil : bmsUnits
    }

    // MARK: Private

    private func buildBMSUnit(
        from values: SensorValues,
        unit: Int,
        prefix: String,
    ) -> BMSStatus? {
        typealias K = SensorKeys.BMS

        // Required: SOC and voltage
        guard
            let soc = values.int(K.soc(prefix: prefix)),
            let voltage = values[K.voltage(prefix: prefix)]
        else {
            return nil
        }

        let current = values[K.current(prefix: prefix)] ?? 0

        // Build CellInfo if cell data available
        let cells = buildCellInfo(from: values, prefix: prefix)

        return BMSStatus(
            unit: unit,
            isConnected: true,
            soc: soc,
            soh: values.int(K.soh(prefix: prefix)),
            voltage: voltage,
            current: current,
            temperature: values[K.temperature(prefix: prefix)],
            chargingVoltage: values[K.chargingVoltage(prefix: prefix)],
            dischargeVoltage: values[K.dischargingVoltage(prefix: prefix)],
            maxChargeCurrent: values[K.maxChargingCurrent(prefix: prefix)],
            maxDischargeCurrent: values[K.maxDischargingCurrent(prefix: prefix)],
            chargeCurrentLimit: values[K.chargingCurrent(prefix: prefix)],
            dischargeCurrentLimit: values[K.dischargingCurrent(prefix: prefix)],
            cells: cells,
            cycles: values.int(K.cycles(prefix: prefix)),
        )
    }

    private func buildCellInfo(from values: SensorValues, prefix: String) -> CellInfo? {
        typealias K = SensorKeys.BMS

        // Need at least min and max cell voltage
        guard
            let minVoltage = values[K.minCellVoltage(prefix: prefix)],
            let maxVoltage = values[K.maxCellVoltage(prefix: prefix)]
        else {
            return nil
        }

        // Calculate delta in mV
        let voltageDelta = Int(max(0, (maxVoltage - minVoltage) * 1000))

        return CellInfo(
            cellCount: values.int(K.cellCount(prefix: prefix)) ?? 16,
            minVoltage: minVoltage,
            maxVoltage: maxVoltage,
            voltageDelta: voltageDelta,
            minTemperature: values[K.minCellTemperature(prefix: prefix)],
            maxTemperature: values[K.maxCellTemperature(prefix: prefix)],
        )
    }
}
