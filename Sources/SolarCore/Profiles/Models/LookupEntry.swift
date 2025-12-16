// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - LookupEntry

/// Lookup entry for enum value mapping.
///
/// Maps register values to human-readable strings.
/// Supports three matching modes:
/// - `key`: exact value match (single or array)
/// - `bit`: bit position match for bitmasks
/// - `key: default`: fallback for unmatched values
///
/// ## Example YAML
///
/// ```yaml
/// lookup:
///   - key: 0x0003
///     value: "Hybrid Inverter"
///   - key: [0x0103, 0x0300]
///     value: "Off-Grid Inverter"
///   - bit: 1
///     value: "Fan failure"
///   - key: default
///     value: "Unknown"
/// ```
public struct LookupEntry: Sendable, Codable, Equatable {
    // MARK: Lifecycle

    public init(key: LookupKey, value: String) {
        self.key = key
        self.value = value
    }

    public init(key: Int, value: String) {
        self.key = .single(key)
        self.value = value
    }

    public init(keys: [Int], value: String) {
        key = .multiple(keys)
        self.value = value
    }

    public init(bit: Int, value: String) {
        key = .bit(bit)
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        value = try container.decode(String.self, forKey: .value)

        // Try bit first
        if let bit = try container.decodeIfPresent(Int.self, forKey: .bit) {
            key = .bit(bit)
        }
        // Then try key (can be Int, [Int], or "default")
        else if container.contains(.key) {
            // Try "default" string
            if let keyString = try? container.decode(String.self, forKey: .key), keyString == "default" {
                key = .default
            }
            // Try single Int
            else if let keyInt = try? container.decode(Int.self, forKey: .key) {
                key = .single(keyInt)
            }
            // Try [Int]
            else if let keyArray = try? container.decode([Int].self, forKey: .key) {
                key = .multiple(keyArray)
            } else {
                throw DecodingError.typeMismatch(
                    LookupKey.self,
                    DecodingError.Context(
                        codingPath: container.codingPath,
                        debugDescription: "Expected Int, [Int], or 'default' for key",
                    ),
                )
            }
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.key,
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Lookup entry must have 'key' or 'bit'",
                ),
            )
        }
    }

    // MARK: Public

    /// Register value(s) that map to this entry.
    /// Can be single value, array of values, bit position, or default.
    public let key: LookupKey

    /// Human-readable value.
    public let value: String

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)

        switch key {
        case let .single(k):
            try container.encode(k, forKey: .key)
        case let .multiple(keys):
            try container.encode(keys, forKey: .key)
        case let .bit(b):
            try container.encode(b, forKey: .bit)
        case .default:
            try container.encode("default", forKey: .key)
        }
    }

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case key
        case bit
        case value
    }
}

// MARK: LookupEntry.LookupKey

extension LookupEntry {
    /// Lookup key can be single value, array, bit position, or default.
    public enum LookupKey: Sendable, Equatable {
        case single(Int)
        case multiple([Int])
        case bit(Int)
        case `default`

        // MARK: Public

        /// All keys as array (empty for bit and default).
        public var keys: [Int] {
            switch self {
            case let .single(key): [key]
            case let .multiple(keys): keys
            case .bit,
                 .default:
                []
            }
        }

        /// Whether this is a default/fallback entry.
        public var isDefault: Bool {
            if case .default = self {
                return true
            }
            return false
        }

        /// Check if this key matches a register value.
        ///
        /// For `.bit` positions >= 64, returns false (multi-register bitmasks
        /// require specialized handling with `decodeUInt64`).
        public func matches(_ registerValue: Int) -> Bool {
            switch self {
            case let .single(key):
                return key == registerValue
            case let .multiple(keys):
                return keys.contains(registerValue)
            case let .bit(position):
                // Safe bit check: positions 0-63 only
                guard position >= 0, position < 64 else {
                    return false
                }
                return (registerValue & (1 << position)) != 0
            case .default:
                // Default matches everything (used as fallback)
                return true
            }
        }
    }
}

// MARK: - Lookup Helper

extension [LookupEntry] {
    /// Find value for a register value.
    ///
    /// Checks non-default entries first, then falls back to default entry if present.
    public func value(for registerValue: Int) -> String? {
        // First try non-default entries
        if let match = first(where: { !$0.key.isDefault && $0.key.matches(registerValue) }) {
            return match.value
        }
        // Then try default entry
        return first { $0.key.isDefault }?.value
    }

    /// Find value for a register value with default.
    public func value(for registerValue: Int, default defaultValue: String) -> String {
        value(for: registerValue) ?? defaultValue
    }
}
