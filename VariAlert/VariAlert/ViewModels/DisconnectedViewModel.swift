// SPDX-License-Identifier: MIT
//
//  DisconnectedViewModel.swift
//  VariAlert
//
//  Created by Carlin Eng on 2/2/25.
//

import SwiftUI
import Combine

class DisconnectedViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var detectedRadars: [RadarDevice] = []
    @Published var isSearching: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isBluetoothEnabled = true
    
    // MARK: - Private Properties
    private var bluetoothManager: BluetoothManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    init(appState: AppStateViewModel) {
        self.bluetoothManager = appState.bluetoothManager
        
        bluetoothManager = appState.bluetoothManager
        bluetoothManager.$discoveredRadars.assign(to: &$detectedRadars)
        bluetoothManager.$isScanning.assign(to: &$isSearching)
        bluetoothManager.$isBluetoothEnabled.assign(to: &$isBluetoothEnabled) // Sync Bluetooth state
    }
    
    // MARK: - Methods
    
    /// Start scanning for radars
    func startSearch() {
        // Begin scanning for radars.
        isSearching = true
        bluetoothManager.startScanning()
        
        // After scanning, update detectedRadars, set isSearching = false.
    }
    
    func stopSearch() {
        // Stop scanning.
        isSearching = false
        bluetoothManager.stopScanning()
    }

    func connectToRadar(_ radar: RadarDevice) {
        // Initiate connection logic via the relevant service.
        // If success, call appState.didConnect(to:)
        // If fail, set errorMessage with reason.
        bluetoothManager.connect(to: radar)
    }
}
