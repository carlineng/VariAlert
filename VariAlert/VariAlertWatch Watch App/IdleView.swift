// SPDX-License-Identifier: MIT
//
//  IdleView.swift
//  VariAlertWatch Watch App
//
//  Created by Carlin Eng on 2/3/25.
//

import SwiftUI

struct IdleView: View {
    @EnvironmentObject var appState: WatchAppState
    @EnvironmentObject var workoutManager: WorkoutSessionManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Idle State")
                .font(.title2)

            Button("Start Workout") {
                // Start a workout session
                workoutManager.startWorkout()
                // Switch mode
                appState.mode = .workout
            }
            .font(.headline)
        }
        .padding()
    }
}
