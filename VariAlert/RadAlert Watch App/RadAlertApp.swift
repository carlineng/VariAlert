// SPDX-License-Identifier: MIT
//
//  RadAlertApp.swift
//  RadAlert Watch App
//
//  Created by Carlin Eng on 2/2/25.
//

import SwiftUI
import WatchKit
import CoreBluetooth

@main
struct RadAlertApp: App {
    @StateObject private var watchAppState: WatchAppState
    @StateObject private var bluetoothManager: BluetoothManager
    @StateObject private var workoutManager: WorkoutSessionManager

    init() {
        _watchAppState = StateObject(wrappedValue: WatchAppState())
        _bluetoothManager = StateObject(wrappedValue: BluetoothManager())
        _workoutManager = StateObject(wrappedValue: WorkoutSessionManager())
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
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var workoutManager: WorkoutSessionManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        NavigationView {
            VStack {
                if !hasCompletedOnboarding {
                    OnboardingView()
                } else if bluetoothManager.bluetoothState == .unknown {
                    ProgressView()
                } else if !bluetoothManager.isAuthorized {
                    BluetoothDeniedView()
                } else if !workoutManager.isHealthKitAuthorized {
                    HealthKitDeniedView()
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
        .onAppear {
            // Re-initialize BT on relaunch if onboarding already done.
            // initialize() is idempotent so it's safe to also call from OnboardingView.
            if hasCompletedOnboarding {
                bluetoothManager.initialize()
            }
        }
    }
}

// MARK: - Denial Views

private struct BluetoothDeniedView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Image(systemName: "bluetooth.slash")
                    .font(.system(size: 32))
                    .foregroundColor(.orange)

                Text("Bluetooth Required")
                    .font(.headline)

                Text("RadAlert needs Bluetooth to connect to your Garmin Varia.\n\nOn your iPhone: Settings → Privacy & Security → Bluetooth → enable RadAlert.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

private struct HealthKitDeniedView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Image(systemName: "heart.slash")
                    .font(.system(size: 32))
                    .foregroundColor(.red)

                Text("Health Access Required")
                    .font(.headline)

                Text("RadAlert needs Health access to track your ride and run in the background.\n\nOn your iPhone: Settings → Health → Data Access & Devices → RadAlert.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}
