// SPDX-License-Identifier: MIT
//
//  RadAlertApp.swift
//  RadAlert Watch App
//
//  Created by Carlin Eng on 2/2/25.
//

import SwiftUI
import WatchKit

@main
struct RadAlertApp: App {
    @StateObject private var watchAppState: WatchAppState
    @StateObject private var bluetoothManager: BluetoothManager
    @StateObject private var workoutManager: WorkoutSessionManager

    init() {
        let aState = WatchAppState()
        let bManager = BluetoothManager()
        let wManager = WorkoutSessionManager()

        _watchAppState = StateObject(wrappedValue: aState)
        _bluetoothManager = StateObject(wrappedValue: bManager)
        _workoutManager = StateObject(wrappedValue: wManager)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bluetoothManager)
                .environmentObject(workoutManager)
                .environmentObject(watchAppState)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: WatchAppState
    @AppStorage("hasAcknowledgedDisclaimer") private var hasAcknowledgedDisclaimer = false

    var body: some View {
        NavigationView {
            VStack {
                if !hasAcknowledgedDisclaimer {
                    DisclaimerView()
                } else {
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
}

#Preview {
    ContentView()
}
