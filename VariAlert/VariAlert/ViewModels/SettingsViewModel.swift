// SPDX-License-Identifier: MIT
//
//  SettingsViewModel.swift
//  VariAlert
//
//  Created by Carlin Eng on 2/2/25.
//

import SwiftUI
import Combine

class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentDevice: RadarDevice?
    @Published var quietModeEnabled: Bool = false
    @Published var appVersion: String = "1.0.0"
    
    // MARK: - Private Properties
    private var bluetoothManager: BluetoothManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    init(bluetoothManager: BluetoothManager) {
        self.bluetoothManager = bluetoothManager
        
        // Observe the connected device from bluetoothManager
//        bluetoothManager.$connectedPeripheral
//            .sink { [weak self] device in
//                self?.currentDevice = device
//            }
//            .store(in: &cancellables)
    }
    
    // MARK: - Methods
    
    /// Toggle quiet mode to mute watch alerts, etc.
    func toggleQuietMode() {
        quietModeEnabled.toggle()
        // Could integrate with watchConnectivity or local logic to silence notifications
    }
    
    /// Disconnect from the radar
    func disconnect() {
        bluetoothManager.disconnect()
    }
}
