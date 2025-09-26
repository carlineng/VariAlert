// SPDX-License-Identifier: MIT
//
//  ContentView.swift
//  VariAlert
//
//  Created by Carlin Eng on 2/2/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var watchConnectivityManager: WatchConnectivityManager
    
    var body: some View {
        NavigationView {
            if appState.isConnected {
                ConnectedView(appState: appState)
            } else {
                DisconnectedView(appState: appState)
            }
        }
    }
}
