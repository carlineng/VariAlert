// SPDX-License-Identifier: MIT
//
//  RadarDevice.swift
//  VariAlert
//
//  Created by Carlin Eng on 2/2/25.
//

import Foundation
import CoreBluetooth

/// Represents a Garmin Varia radar device.
struct RadarDevice: Identifiable, Equatable {
    let id: UUID = UUID()         // Unique identifier for SwiftUI lists.
    
    // Placeholder properties; these will be used in real logic later.
    let deviceName: String
    let batteryLevel: Int
    let firmwareVersion: String
    let signalStrength: String
    let peripheral: CBPeripheral
    
    // You could also store a device ID from the Bluetooth discovery.
    // let bluetoothIdentifier: String
    
    // Example equality check comparing all relevant fields (or just 'id' if unique)
    static func == (lhs: RadarDevice, rhs: RadarDevice) -> Bool {
        return lhs.id == rhs.id
            && lhs.deviceName == rhs.deviceName
            && lhs.batteryLevel == rhs.batteryLevel
            && lhs.firmwareVersion == rhs.firmwareVersion
            && lhs.signalStrength == rhs.signalStrength
    }
}
