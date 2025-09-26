// SPDX-License-Identifier: MIT
//
//  Threat.swift
//  VariAlert
//
//  Created by Carlin Eng on 2/2/25.
//

import Foundation

/// Represents a detected vehicle threat from the Garmin Varia radar.
struct Threat: Identifiable {
    let id: UInt8        // Unique identifier per threat
    let distance: UInt8  // Distance to the threat in meters
    let speed: UInt8     // Speed in km/h (raw value)
}
