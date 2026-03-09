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

            if bluetoothManager.savedRadar != nil {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gear")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                .buttonStyle(.plain)
            }

            Link("Privacy Policy",
                 destination: URL(string: "https://carlineng.github.io/RadAlert/privacy.html")!)
                .font(.caption2)
                .foregroundColor(.secondary)
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
