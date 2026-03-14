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
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.caption)
                        Text("RadAlert")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)

                    Spacer().frame(height: 4)

                    Button("Start Ride") {
                        if bluetoothManager.savedRadar != nil {
                            workoutManager.startWorkout { success in
                                guard success else { return }
                                appState.mode = .workout
                            }
                        } else {
                            bluetoothManager.discoveredDevices = []
                            bluetoothManager.startScanning()
                            showingRadarSelection = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.headline)

                    if let radar = bluetoothManager.savedRadar {
                        Text(radar.displayName ?? "Varia Radar")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button("Radar Settings") {
                    showingSettings = true
                }
                .font(.caption2)
                .foregroundColor(.secondary)
                .buttonStyle(.plain)
            }
            .padding()

            LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
                .frame(height: 3)
                .ignoresSafeArea(edges: .top)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(onDismiss: { showingSettings = false })
        }
        .sheet(isPresented: $showingRadarSelection) {
            RadarSelectionView(
                onConnect: { device in
                    bluetoothManager.saveRadar(device)
                    bluetoothManager.stopScanning()
                    showingRadarSelection = false
                    workoutManager.startWorkout { success in
                        guard success else { return }
                        appState.mode = .workout
                    }
                },
                onCancel: {
                    bluetoothManager.stopScanning()
                    showingRadarSelection = false
                }
            )
        }
    }
}
