// SPDX-License-Identifier: MIT
//
//  DisconnectedView.swift
//  VariAlert
//
//  Created by Carlin Eng on 2/2/25.
//

import SwiftUI

struct DisconnectedView: View {

    @EnvironmentObject var appState: AppStateViewModel
    @StateObject private var viewModel: DisconnectedViewModel

    init(appState: AppStateViewModel) {
        let vm = DisconnectedViewModel(appState: appState)
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Disconnected")
                .font(.largeTitle)
            
            if viewModel.isSearching {
                Text("Searching...")
                    .foregroundColor(.blue)
            } else {
                Button("Search for Radars") {
                    viewModel.startSearch()
                }
            }
            
            // Display discovered radars
            if !viewModel.isBluetoothEnabled {
                Text("Please enable Bluetooth")
                    .foregroundColor(.red)
                    .padding()
            } else {
                if viewModel.detectedRadars.isEmpty && !viewModel.isSearching {
                    Text("No radars found.")
                        .foregroundColor(.gray)
                        .padding()
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }
                
                List(viewModel.detectedRadars) { radar in
                    Button(radar.deviceName) {
                        // Attempt to connect
                        viewModel.connectToRadar(radar)
                    }
                }
            }
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Private Methods
//    private func connectToDevice(_ device: RadarDevice) {
//        // You’d normally use the real bluetoothManager here
//        // For the stub, just pretend we connected successfully:
//        print("Connecting to \(device.name)")
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            // Simulate success
//            appState.isConnected = true
//        }
//    }
}
