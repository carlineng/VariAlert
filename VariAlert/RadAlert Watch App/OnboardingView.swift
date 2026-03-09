// SPDX-License-Identifier: MIT
//
//  OnboardingView.swift
//  RadAlert Watch App
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var workoutManager: WorkoutSessionManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var currentPage = 0

    var body: some View {
        TabView(selection: $currentPage) {
            // Page 1: What it does
            OnboardingPage(
                systemImage: "antenna.radiowaves.left.and.right",
                title: "RadAlert",
                message: "Provides supplemental haptic alerts from your Garmin Varia radar when vehicles approach from behind.",
                button: nil
            )
            .tag(0)

            // Page 2: What you need
            OnboardingPage(
                systemImage: "checklist",
                title: "What You Need",
                message: "• Garmin Varia radar (RTL 515, RTL 516, or compatible)\n• Bluetooth — to connect to the radar\n• Health — to track your ride and keep the app running in the background",
                button: nil
            )
            .tag(1)

            // Page 3: Safety notice + Get Started
            OnboardingPage(
                systemImage: "exclamationmark.triangle",
                title: "Safety Notice",
                message: "RadAlert is a supplemental awareness tool, not a certified safety device. Always follow traffic laws and rely on your own judgement.",
                button: ("Get Started", getStarted)
            )
            .tag(2)
        }
        .tabViewStyle(.page)
    }

    private func getStarted() {
        bluetoothManager.initialize()
        workoutManager.requestAuthorization { _ in }
        hasCompletedOnboarding = true
    }
}

private struct OnboardingPage: View {
    let systemImage: String
    let title: String
    let message: String
    let button: (String, () -> Void)?

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 32))
                    .foregroundColor(.blue)

                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)

                if let (label, action) = button {
                    Button(label, action: action)
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .padding(.top, 4)
                }
            }
            .padding()
        }
    }
}
