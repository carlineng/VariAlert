// SPDX-License-Identifier: MIT
//
//  SettingsView.swift
//  RadAlert Watch App
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    let onDismiss: () -> Void

    @State private var showingRadarSelection = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Settings")
                    .font(.headline)

                if let saved = bluetoothManager.savedRadar {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(saved.displayName ?? "Varia Radar")
                            .font(.caption)
                        Text("ID: ···\(saved.identifierSuffix)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        if let date = saved.lastConnectedAt {
                            Text("Last connected: \(date.formatted(.dateTime.month().day()))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                }

                Button("Change Radar") {
                    bluetoothManager.discoveredDevices = []
                    bluetoothManager.startScanning()
                    showingRadarSelection = true
                }

                Button("Forget Radar") {
                    bluetoothManager.forgetSavedRadar()
                    onDismiss()
                }
                .foregroundColor(.red)

                Link("Privacy Policy",
                     destination: URL(string: "https://carlineng.github.io/RadAlert/privacy.html")!)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Button("Done", action: onDismiss)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .sheet(isPresented: $showingRadarSelection) {
            RadarSelectionView(
                onConnect: { device in
                    bluetoothManager.saveRadar(device)
                    bluetoothManager.stopScanning()
                    showingRadarSelection = false
                    onDismiss()
                },
                onCancel: {
                    bluetoothManager.stopScanning()
                    showingRadarSelection = false
                }
            )
        }
    }
}
