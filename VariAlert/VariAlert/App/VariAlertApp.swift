// SPDX-License-Identifier: MIT
//
//  VariAlertApp.swift
//  VariAlert
//
//  Created by Carlin Eng on 2/2/25.
//

import SwiftUI

@main
struct VariAlertApp: App {
    // Optionally create shared singletons or environment objects here
    @StateObject private var appState = AppStateViewModel()
    @StateObject private var watchConnectivityManager = WatchConnectivityManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(watchConnectivityManager)
        }
    }
}
