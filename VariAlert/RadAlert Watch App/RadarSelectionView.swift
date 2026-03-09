// SPDX-License-Identifier: MIT
//
//  RadarSelectionView.swift
//  RadAlert Watch App
//

import SwiftUI

struct RadarSelectionView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    let onConnect: (DiscoveredRadar) -> Void
    let onCancel: () -> Void

    @State private var selectedDevice: DiscoveredRadar?

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("Select Radar")
                    .font(.headline)

                selectionContent

                Divider()

                // Connect button — enabled when single device or row is selected
                let connectTarget = singleDevice ?? selectedDevice
                Button("Connect") {
                    if let device = connectTarget {
                        onConnect(device)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(connectTarget == nil)

                Button("Rescan") {
                    selectedDevice = nil
                    bluetoothManager.discoveredDevices = []
                    bluetoothManager.startScanning()
                }
                .foregroundColor(.orange)
                .disabled(bluetoothManager.isScanning)

                Button("Cancel", action: onCancel)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }

    // MARK: - Content States

    @ViewBuilder
    private var selectionContent: some View {
        if bluetoothManager.isScanning {
            VStack(spacing: 6) {
                ProgressView()
                Text("Scanning...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(minHeight: 60)
        } else if bluetoothManager.discoveredDevices.isEmpty {
            VStack(spacing: 6) {
                Text("No radar found")
                    .font(.caption)
                Text("Make sure your Garmin Varia is powered on and nearby.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        } else if let device = singleDevice {
            // Single-confirm state
            VStack(spacing: 4) {
                Text("Found 1 radar:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(device.name)
                    .font(.headline)
                Text("ID ending in \(device.identifierSuffix)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        } else {
            // Multi-list state
            ForEach(bluetoothManager.discoveredDevices) { device in
                Button {
                    selectedDevice = device
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(device.name)
                                    .font(.caption)
                                if device.isSaved {
                                    Text("Saved")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                            }
                            Text("·\(device.identifierSuffix)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if selectedDevice?.id == device.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var singleDevice: DiscoveredRadar? {
        bluetoothManager.discoveredDevices.count == 1 ? bluetoothManager.discoveredDevices.first : nil
    }
}
