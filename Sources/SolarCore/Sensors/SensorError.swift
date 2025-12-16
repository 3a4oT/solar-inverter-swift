// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

/// Errors that can occur during sensor value conversion.
public enum SensorError: Error, Sendable, Equatable {
    /// Not enough registers provided for the data type.
    case insufficientRegisters(expected: Int, got: Int)

    /// Raw value is outside the valid range (ha-solarman `range` filtering).
    /// This occurs before transformation and means the sensor should be skipped.
    case rawValueOutOfRange(value: Double, min: Double?, max: Double?)

    /// Transformed value is outside the valid range (post-transformation validation).
    case valueOutOfRange(value: Double, min: Double?, max: Double?)

    /// Invalid bit index for bitmask extraction.
    case invalidBitIndex(index: UInt8)

    /// String contains invalid UTF-8 encoding.
    case invalidUTF8

    /// String contains control characters (security violation).
    /// Parameter is the Unicode scalar value of the first control character found.
    case controlCharacter(UInt32)

    /// Parsing rule not supported for numeric conversion.
    case unsupportedRule(ParsingRule)
}
