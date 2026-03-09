// SPDX-License-Identifier: MIT
//
//  IdleView.swift
//  RadAlert Watch App
//
//  Created by Carlin Eng on 2/3/25.
//

import SwiftUI

struct IdleView: View {
    @EnvironmentObject var appState: WatchAppState
    @EnvironmentObject var workoutManager: WorkoutSessionManager
    @EnvironmentObject var bluetoothManager: BluetoothManager

    @State private var showingSettings = false
    @State private var showingRadarSelection = false

    var body: some View {
        VStack(spacing: 16) {
            Text("RadAlert")
                .font(.title2)

            Button("Start Ride") {
                if bluetoothManager.savedRadar != nil {
                    workoutManager.startWorkout()
                    appState.mode = .workout
                } else {
                    bluetoothManager.discoveredDevices = []
                    bluetoothManager.startScanning()
                    showingRadarSelection = true
                }
            }
            .font(.headline)

            Button("Settings") {
                showingSettings = true
            }
            .font(.caption2)
            .foregroundColor(.secondary)
            .buttonStyle(.plain)
        }
        .padding()
        .sheet(isPresented: $showingSettings) {
            SettingsView(onDismiss: { showingSettings = false })
        }
        .sheet(isPresented: $showingRadarSelection) {
            RadarSelectionView(
                onConnect: { device in
                    bluetoothManager.saveRadar(device)
                    bluetoothManager.stopScanning()
                    showingRadarSelection = false
                    workoutManager.startWorkout()
                    appState.mode = .workout
                },
                onCancel: {
                    bluetoothManager.stopScanning()
                    showingRadarSelection = false
                }
            )
        }
    }
}
