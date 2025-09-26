// SPDX-License-Identifier: MIT
//
//  VariAlertWatchApp.swift
//  VariAlertWatch Watch App
//
//  Created by Carlin Eng on 2/2/25.
//

import SwiftUI
import WatchKit
import UserNotifications

@main
struct VariAlertWatch_Watch_AppApp: App {
    // Declare your state objects without initial values:
    @StateObject private var watchAppState: WatchAppState
    @StateObject private var connectivityManager: WatchConnectivityManager
    @StateObject private var workoutManager: WorkoutSessionManager

    init() {
        // 1. Manually create all the instances we need:
        let aState = WatchAppState()
        let cManager = WatchConnectivityManager(appState: aState)
        let wManager = WorkoutSessionManager()

        // 2. Wrap each instance in StateObject:
        _watchAppState = StateObject(wrappedValue: aState)
        _connectivityManager = StateObject(wrappedValue: cManager)
        _workoutManager = StateObject(wrappedValue: wManager)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectivityManager)
                .environmentObject(workoutManager)
                .environmentObject(watchAppState)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: WatchAppState

    var body: some View {
        NavigationView {
            VStack {
                switch appState.mode {
                case .idle:
                    IdleView()
                case .workout:
                    WorkoutView()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
