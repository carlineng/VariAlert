// SPDX-License-Identifier: MIT
//
//  AppStateViewModel.swift
//  VariAlert
//
//  Created by Carlin Eng on 2/2/25.
//

import SwiftUI
import Combine

/// High-level app state: whether a radar is connected, etc.
class AppStateViewModel: ObservableObject {
    @Published var isConnected: Bool = false
    
    // Potentially store the currently connected device.
    @Published var connectedRadar: RadarDevice? = nil
    
    // Dependencies for scanning, connecting, etc.
    let bluetoothManager: BluetoothManager
    
    init() {
        self.bluetoothManager = BluetoothManager()
        self.bluetoothManager.appState = self
    }
    
    /// Called when a successful connection to a radar is established
    func didConnect(to device: RadarDevice) {
        self.connectedRadar = device
        self.isConnected = true
    }
    
    /// Called when the radar is disconnected
    func didDisconnect() {
        self.connectedRadar = nil
        self.isConnected = false
    }
}
