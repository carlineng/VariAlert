// SPDX-License-Identifier: MIT
//
//  WorkoutView.swift
//  VariAlertWatch Watch App
//
//  Created by Carlin Eng on 2/3/25.
//

import SwiftUI

struct WorkoutView: View {
    @EnvironmentObject var appState: WatchAppState
    @EnvironmentObject var workoutManager: WorkoutSessionManager
    
    // Use a state to track whether the user is currently long-pressing
    @State private var isPressing = false
    @State private var currentTime = Date()
    
    var body: some View {
        VStack(spacing: 16) {
            // Display the current time in HH:MM format
            Text(timeFormatter.string(from: currentTime))
                .font(.title)

            Text("Workout Active")
                .font(.subheadline)

            // Pause Ride Button
            Button(action: {}) {
                Text("Pause Ride")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isPressing ? Color.red.opacity(0.7) : Color.red) // Changes shade when pressed
                    .cornerRadius(10)
            }
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 1.0) // 1 second press required
                    .onChanged { _ in isPressing = true } // Start changing button shade
                    .onEnded { _ in
                        isPressing = false
                        stopWorkoutSession() // Trigger app state change
                    }
            )
        }
        .padding()
        .onAppear {
            startTimeUpdater()
        }
    }
    
    // Time formatter for HH:MM format
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateFormat = "HH:mm"
        return formatter
    }
    
    // Update time every minute
    private func startTimeUpdater() {
        currentTime = Date()
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            currentTime = Date()
        }
    }
    
    private func stopWorkoutSession() {
        workoutManager.stopWorkout()
        appState.mode = .idle
    }
}
