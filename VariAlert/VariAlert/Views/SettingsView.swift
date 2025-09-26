// SPDX-License-Identifier: MIT
//
//  SettingsView.swift
//  VariAlert
//
//  Created by Carlin Eng on 2/2/25.
//

import SwiftUI

struct SettingsView: View {
    // You might want an @ObservedObject or @EnvironmentObject
    // For this stub, we’ll just create one locally.
    @StateObject private var viewModel = SettingsViewModel(bluetoothManager: BluetoothManager())
    
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Device Management")) {
                    if let device = viewModel.currentDevice {
                        Text("Connected to: \(device.deviceName)")
                        Text("Battery: \(device.batteryLevel)%")
                        Button("Disconnect") {
                            viewModel.disconnect()
                            presentationMode.wrappedValue.dismiss()
                        }
                    } else {
                        Text("No device connected.")
                    }
                }
                
                Section(header: Text("Alerts")) {
                    Toggle("Quiet Mode", isOn: $viewModel.quietModeEnabled)
                        .onChange(of: viewModel.quietModeEnabled) { _ in
                            viewModel.toggleQuietMode()
                        }
                }
                
                Section(header: Text("App Information")) {
                    Text("App Version: \(viewModel.appVersion)")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
