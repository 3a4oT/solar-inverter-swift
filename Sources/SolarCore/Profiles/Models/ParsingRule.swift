// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

// MARK: - ParsingRule

/// Parsing rule for register value interpretation.
///
/// Matches the `rule` field in upstream ha-solarman sensor items.
/// Each rule defines how to convert raw register bytes to typed values.
///
/// ## Rules Reference
///
/// | Rule | Type | Registers | Description |
/// |------|------|-----------|-------------|
/// | 0 | Computed | 0 | Derived from other sensors |
/// | 1 | U16 | 1 | Unsigned 16-bit |
/// | 2 | S16 | 1 | Signed 16-bit |
/// | 3 | U32 | 2 | Unsigned 32-bit (high word first) |
/// | 4 | S32 | 2 | Signed 32-bit (high word first) |
/// | 5 | ASCII | N | String (2 chars per register) |
/// | 6 | Bits | N | Hex string array |
/// | 7 | Version | 1 | Nibble-delimited string |
/// | 8 | DateTime | 3-6 | Date/time value |
/// | 9 | Time | 1-6 | Time value (HHMM) |
/// | 10 | Raw | N | Raw register array |
public enum ParsingRule: Int, Sendable, Codable, Equatable, CaseIterable {
    /// Computed value (no register read).
    case computed = 0

    /// Unsigned 16-bit integer.
    case uint16 = 1

    /// Signed 16-bit integer.
    case int16 = 2

    /// Unsigned 32-bit integer (high word first).
    case uint32 = 3

    /// Signed 32-bit integer (high word first).
    case int32 = 4

    /// ASCII string (2 characters per register).
    case ascii = 5

    /// Bit values as hex strings.
    case bits = 6

    /// Version string (nibble-delimited).
    case version = 7

    /// Date/time value.
    case datetime = 8

    /// Time value (HHMM format).
    case time = 9

    /// Raw register values.
    case raw = 10
}

// MARK: - Convenience Properties

extension ParsingRule {
    /// Whether this rule produces numeric output.
    public var isNumeric: Bool {
        switch self {
        case .uint16,
             .int16,
             .uint32,
             .int32,
             .time: // Time is numeric (HHMM format as integer)
            true
        default:
            false
        }
    }

    /// Whether this rule uses signed interpretation.
    public var isSigned: Bool {
        switch self {
        case .int16,
             .int32:
            true
        default:
            false
        }
    }

    /// Expected number of registers (0 = variable).
    public var expectedRegisters: Int {
        switch self {
        case .computed:
            0
        case .uint16,
             .int16,
             .version:
            1
        case .uint32,
             .int32:
            2
        case .ascii,
             .bits,
             .datetime,
             .time,
             .raw:
            0 // Variable
        }
    }
}
