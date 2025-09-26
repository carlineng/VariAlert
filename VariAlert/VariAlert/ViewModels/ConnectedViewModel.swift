// SPDX-License-Identifier: MIT
//
//  ConnectedViewModel.swift
//  VariAlert
//
//  Created by Carlin Eng on 2/2/25.
//

import SwiftUI
import Combine

class ConnectedViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var vehicleCount: Int = 0
    @Published var lastAlertTimestamp: Date? = nil
    @Published var lastNotificationTime: String? = "No notifications sent yet"

    // MARK: - Private Properties
    private var bluetoothManager: BluetoothManager
    private var cancellables = Set<AnyCancellable>()
    
    // Keep track of Threat IDs we've seen
    private var lastThreatIDs: Set<UInt8> = []

    // MARK: - Init
    init(appState: AppStateViewModel) {
        self.bluetoothManager = appState.bluetoothManager
        
        // Observe device connection changes
        bluetoothManager.onThreatsReceived = { [weak self] data in
            DispatchQueue.main.async {
                self?.handleReceivedData(data)
            }
        }
    }
    
    private func handleReceivedData(_ threats: [Threat]) {
        // Compare the latest Threat report to the prior state.
        // If there is a new Threat, send an alert via haptic notification
        // Map current threats to their IDs (assuming Threat has an `id` property)
        let currentThreatIDs = Set(threats.map { $0.id })
        
        // Identify new threats: those present in the current update but not in the last snapshot
        let newThreatIDs = currentThreatIDs.subtracting(lastThreatIDs)
        
        if !newThreatIDs.isEmpty {
            // Trigger notification
            print("Sending alert to Watch.")
            WatchConnectivityManager.shared.sendCarDetectedAlert()
            
            //  update alert timestamp
            lastAlertTimestamp = Date()
            updateLastNotificationTime()  // ✅ Format timestamp for display
        }
        
        // Update our state with the latest threat IDs
        lastThreatIDs = currentThreatIDs
        DispatchQueue.main.async {
            self.vehicleCount = self.lastThreatIDs.count
            print("Total threats observed: \(self.vehicleCount)")
        }
    }

    // MARK: - Methods
    
    /// Format the last notification timestamp for display
    private func updateLastNotificationTime() {
        DispatchQueue.main.async {
            if let lastAlertTimestamp = self.lastAlertTimestamp {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                self.lastNotificationTime = "Last Alert: \(formatter.string(from: lastAlertTimestamp))"
            } else {
                self.lastNotificationTime = "No notifications sent yet"
            }
        }
    }
    
    /// Placeholder for handling new vehicle detection
    func onVehicleDetected(count: Int) {
        vehicleCount = count
        
        // Notify Apple Watch
//        watchConnectivityManager.sendCarDetectedAlert()
    }
    
    /// Disconnect from the current device
    func disconnect() {
        bluetoothManager.disconnect()
    }
}
