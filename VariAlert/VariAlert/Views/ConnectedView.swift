// SPDX-License-Identifier: MIT
//
//  ConnectedView.swift
//  VariAlert
//
//  Created by Carlin Eng on 2/2/25.
//

import SwiftUI

struct ConnectedView: View {
    @StateObject var viewModel: ConnectedViewModel
    @EnvironmentObject var appState: AppStateViewModel
    
    @State private var showSettings = false
    

    init(appState: AppStateViewModel) {
        _viewModel = StateObject(wrappedValue: ConnectedViewModel(appState: appState))
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Connected Screen")
                .font(.largeTitle)
            
            Text(viewModel.lastNotificationTime != nil ? "Last notification time: \(viewModel.lastNotificationTime!)" : "No notifications sent yet")
                .foregroundColor(.gray)

            // Show vehicle detection
            if viewModel.vehicleCount > 0 {
                Text("\(viewModel.vehicleCount) vehicles detected!")
                    .foregroundColor(.red)
            } else {
                Text("No vehicles detected.")
                    .foregroundColor(.green)
            }
                        
            // Button to open settings
            Button("Settings") {
                showSettings.toggle()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            
            // Disconnect button
            Button("Disconnect") {
                disconnectDevice()
            }
            .foregroundColor(.red)
            
            Spacer()
        }
        .padding()
    }
    
    private func disconnectDevice() {
        viewModel.disconnect()
        // In a real app, you'd also have a binding or environment object
        // to transition back to DisconnectedView automatically.
    }
}
