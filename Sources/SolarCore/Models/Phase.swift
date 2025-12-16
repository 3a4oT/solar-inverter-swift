// SPDX-License-Identifier: Apache-2.0
// Copyright 2025 Petro Rovenskyi

/// AC phase identifier for three-phase systems.
public enum Phase: String, Sendable, Codable, CaseIterable {
    /// Phase L1 (single-phase systems use only this).
    case l1

    /// Phase L2 (three-phase only).
    case l2

    /// Phase L3 (three-phase only).
    case l3
}
