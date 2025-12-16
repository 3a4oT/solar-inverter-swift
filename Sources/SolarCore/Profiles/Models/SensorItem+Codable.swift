// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - SensorItem + Codable

extension SensorItem: Codable {
    // MARK: Lifecycle

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required
        name = try container.decode(String.self, forKey: .name)
        rule = try container.decode(ParsingRule.self, forKey: .rule)

        // Registers: [Int] from YAML → [UInt16] with validation
        let rawRegisters = try container.decodeIfPresent([Int].self, forKey: .registers) ?? []
        registers = try Self.decodeRegisters(
            rawRegisters, codingPath: container.codingPath + [CodingKeys.registers],
        )

        // Platform & Classification (with defaults)
        platform = try container.decodeIfPresent(Platform.self, forKey: .platform) ?? .sensor
        deviceClass = try container.decodeIfPresent(DeviceClass.self, forKey: .deviceClass)
        stateClass = try container.decodeIfPresent(StateClass.self, forKey: .stateClass)
        uom = try container.decodeIfPresent(String.self, forKey: .uom) ?? ""
        icon = try container.decodeIfPresent(String.self, forKey: .icon)

        // Transformation (with defaults)
        scale = try Self.decodeScale(from: container) ?? 1.0
        offset = try container.decodeIfPresent(Double.self, forKey: .offset) ?? 0.0
        signed = try container.decodeIfPresent(Bool.self, forKey: .signed) ?? false
        inverse = try container.decodeIfPresent(Bool.self, forKey: .inverse) ?? false
        magnitude = try container.decodeIfPresent(Bool.self, forKey: .magnitude) ?? false

        // Bit manipulation
        mask = try Self.decodeHexOrInt(from: container, forKey: .mask)
        divide = try Self.decodeHexOrInt(from: container, forKey: .divide)
        bit = try container.decodeIfPresent(UInt8.self, forKey: .bit)

        // Range filtering (raw value)
        if let rangeContainer = try? container.nestedContainer(keyedBy: RangeKeys.self, forKey: .range) {
            rangeMin = Self.decodeFlexibleDouble(from: rangeContainer, forKey: .min)
            rangeMax = Self.decodeFlexibleDouble(from: rangeContainer, forKey: .max)
            rangeDefault = Self.decodeFlexibleDouble(from: rangeContainer, forKey: .default)
        } else {
            rangeMin = nil
            rangeMax = nil
            rangeDefault = nil
        }

        // Validation (post-transformation, values can be Double or [Double])
        if let validationContainer = try? container.nestedContainer(
            keyedBy: RangeKeys.self, forKey: .validation,
        ) {
            validationMin = Self.decodeFlexibleDouble(from: validationContainer, forKey: .min)
            validationMax = Self.decodeFlexibleDouble(from: validationContainer, forKey: .max)
        } else {
            validationMin = nil
            validationMax = nil
        }

        // Lookup
        lookup = try container.decodeIfPresent([LookupEntry].self, forKey: .lookup) ?? []
        options = try container.decodeIfPresent([String].self, forKey: .options) ?? []

        // Composite
        subSensors = try Self.decodeSubSensors(from: container)
        attributeNames = try container.decodeIfPresent([String].self, forKey: .attributes) ?? []

        // Attribute flag (can be bool or string)
        isAttribute = try Self.decodeAttributeFlag(from: container)

        // Metadata
        description = try container.decodeIfPresent(String.self, forKey: .description)
        updateInterval = try container.decodeIfPresent(Int.self, forKey: .updateInterval)

        // Version parsing (rule 7)
        versionDelimiter = try Self.decodeVersionDelimiter(from: container)
        hex = try Self.decodeHexFlag(from: container)
    }

    // MARK: Public

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(name, forKey: .name)
        try container.encode(registers.map { Int($0) }, forKey: .registers)
        try container.encode(rule, forKey: .rule)
        try container.encode(platform, forKey: .platform)
        try container.encodeIfPresent(deviceClass, forKey: .deviceClass)
        try container.encodeIfPresent(stateClass, forKey: .stateClass)
        if !uom.isEmpty {
            try container.encode(uom, forKey: .uom)
        }
        try container.encodeIfPresent(icon, forKey: .icon)
        if scale != 1.0 {
            try container.encode(scale, forKey: .scale)
        }
        if offset != 0.0 {
            try container.encode(offset, forKey: .offset)
        }
        if signed {
            try container.encode(signed, forKey: .signed)
        }
        if inverse {
            try container.encode(inverse, forKey: .inverse)
        }
        if magnitude {
            try container.encode(magnitude, forKey: .magnitude)
        }
        if let mask {
            try container.encode(Int(mask), forKey: .mask)
        }
        if let divide {
            try container.encode(Int(divide), forKey: .divide)
        }
        if let bit {
            try container.encode(bit, forKey: .bit)
        }

        if rangeMin != nil || rangeMax != nil || rangeDefault != nil {
            var rangeContainer = container.nestedContainer(keyedBy: RangeKeys.self, forKey: .range)
            try rangeContainer.encodeIfPresent(rangeMin, forKey: .min)
            try rangeContainer.encodeIfPresent(rangeMax, forKey: .max)
            try rangeContainer.encodeIfPresent(rangeDefault, forKey: .default)
        }

        if validationMin != nil || validationMax != nil {
            var validationContainer = container.nestedContainer(
                keyedBy: RangeKeys.self, forKey: .validation,
            )
            try validationContainer.encodeIfPresent(validationMin, forKey: .min)
            try validationContainer.encodeIfPresent(validationMax, forKey: .max)
        }

        if !lookup.isEmpty {
            try container.encode(lookup, forKey: .lookup)
        }
        if !options.isEmpty {
            try container.encode(options, forKey: .options)
        }
        if !subSensors.isEmpty {
            try container.encode(subSensors, forKey: .sensors)
        }
        if !attributeNames.isEmpty {
            try container.encode(attributeNames, forKey: .attributes)
        }
        if isAttribute {
            try container.encode(isAttribute, forKey: .attribute)
        }
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(updateInterval, forKey: .updateInterval)

        // Version parsing
        if versionDelimiter != .default {
            if versionDelimiter.digit == versionDelimiter.register || versionDelimiter.register == "-" {
                try container.encode(versionDelimiter.digit, forKey: .delimiter)
            } else {
                var delimiterContainer = container.nestedContainer(
                    keyedBy: DelimiterKeys.self, forKey: .delimiter,
                )
                try delimiterContainer.encode(versionDelimiter.digit, forKey: .digit)
                try delimiterContainer.encode(versionDelimiter.register, forKey: .register)
            }
        }
        if hex {
            try container.encode(hex, forKey: .hex)
        }
    }

    // MARK: Internal

    enum CodingKeys: String, CodingKey {
        case name
        case registers
        case rule
        case platform
        case deviceClass = "class"
        case stateClass = "state_class"
        case uom
        case icon
        case scale
        case offset
        case signed
        case inverse
        case magnitude
        case mask
        case divide
        case bit
        case range
        case validation
        case lookup
        case options
        case sensors
        case attributes
        case attribute
        case description
        case updateInterval = "update_interval"
        case delimiter
        case hex
    }

    enum RangeKeys: String, CodingKey {
        case min
        case max
        case `default`
    }

    enum DelimiterKeys: String, CodingKey {
        case digit
        case register
    }
}

// MARK: - Decoding Helpers

extension SensorItem {
    /// DTO for sub-sensor decoding.
    struct SubSensorDTO: Codable {
        let registers: [Int]
        let scale: Double?
        let offset: Double?
        let signed: Bool?
        let `operator`: SubSensor.Operator?
    }

    /// Validate and convert register addresses from Int to UInt16.
    static func decodeRegisters(_ rawRegisters: [Int], codingPath: [CodingKey]) throws -> [UInt16] {
        try rawRegisters.map { raw in
            guard (0...65535).contains(raw) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: codingPath,
                        debugDescription: "Register address \(raw) out of UInt16 range",
                    ),
                )
            }
            return UInt16(raw)
        }
    }

    /// Decode scale which can be Double or [Double].
    static func decodeScale(from container: KeyedDecodingContainer<CodingKeys>) throws -> Double? {
        if let single = try? container.decode(Double.self, forKey: .scale) {
            return single
        }
        if let array = try? container.decode([Double].self, forKey: .scale), let first = array.first {
            return first
        }
        return nil
    }

    /// Decode a value that can be Double or [Double], taking first element if array.
    static func decodeFlexibleDouble<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K,
    ) -> Double? {
        if let single = try? container.decode(Double.self, forKey: key) {
            return single
        }
        if let array = try? container.decode([Double].self, forKey: key), let first = array.first {
            return first
        }
        return nil
    }

    /// Decode sub-sensors from `sensors` field.
    static func decodeSubSensors(from container: KeyedDecodingContainer<CodingKeys>) throws
        -> [SubSensor] {
        guard let rawSensors = try? container.decode([SubSensorDTO].self, forKey: .sensors) else {
            return []
        }
        return try rawSensors.map { dto in
            let registers = try decodeRegisters(dto.registers, codingPath: container.codingPath)
            return SubSensor(
                registers: registers,
                scale: dto.scale ?? 1.0,
                offset: dto.offset ?? 0.0,
                signed: dto.signed ?? false,
                operator: dto.operator ?? .add,
            )
        }
    }

    /// Decode attribute flag (bool or string presence).
    static func decodeAttributeFlag(from container: KeyedDecodingContainer<CodingKeys>) throws -> Bool {
        if let boolValue = try? container.decode(Bool.self, forKey: .attribute) {
            return boolValue
        }
        if (try? container.decode(String.self, forKey: .attribute)) != nil {
            return true
        }
        return false
    }

    /// Decode hex or integer value as UInt32.
    /// YAML can have: `mask: 0x0F00` or `mask: 256`
    static func decodeHexOrInt(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys,
    ) throws -> UInt32? {
        // Try as Int first (covers both decimal and hex literals in YAML)
        if let intValue = try? container.decode(Int.self, forKey: key) {
            guard intValue >= 0, intValue <= UInt32.max else {
                return nil
            }
            return UInt32(intValue)
        }
        return nil
    }

    /// Decode version delimiter configuration.
    ///
    /// YAML formats:
    /// - `delimiter: "."` → digit=".", register="-"
    /// - `delimiter: ""` → digit="", register="-"
    /// - `delimiter: { digit: ".", register: "-" }` → custom both
    static func decodeVersionDelimiter(from container: KeyedDecodingContainer<CodingKeys>) throws
        -> VersionDelimiter {
        // Try as string first (simple format)
        if let stringValue = try? container.decode(String.self, forKey: .delimiter) {
            return VersionDelimiter(delimiter: stringValue)
        }

        // Try as nested container (complex format)
        if let delimiterContainer = try? container.nestedContainer(
            keyedBy: DelimiterKeys.self, forKey: .delimiter,
        ) {
            let digit = try delimiterContainer.decodeIfPresent(String.self, forKey: .digit) ?? "."
            let register = try delimiterContainer.decodeIfPresent(String.self, forKey: .register) ?? "-"
            return VersionDelimiter(digit: digit, register: register)
        }

        // Default
        return .default
    }

    /// Decode hex flag for version parsing.
    ///
    /// YAML: `hex:` (presence means true) or `hex: true`
    static func decodeHexFlag(from container: KeyedDecodingContainer<CodingKeys>) throws -> Bool {
        // Check for explicit bool value
        if let boolValue = try? container.decode(Bool.self, forKey: .hex) {
            return boolValue
        }
        // Check for presence (empty value means true, like `hex:` in YAML)
        if container.contains(.hex) {
            // If key exists but no value, it's a flag
            if (try? container.decodeNil(forKey: .hex)) == true {
                return true
            }
        }
        return false
    }
}
