// SPDX-License-Identifier: MIT
//
//  IdleView.swift
//  RadAlert Watch App
//
//  Created by Carlin Eng on 2/3/25.
//

import SwiftUI

struct IdleView: View {
    @EnvironmentObject var appState: WatchAppState
    @EnvironmentObject var workoutManager: WorkoutSessionManager

    var body: some View {
        VStack(spacing: 16) {
            Text("RadAlert")
                .font(.title2)

            Button("Start Ride") {
                workoutManager.startWorkout()
                appState.mode = .workout
            }
            .font(.headline)

            Link("Privacy Policy",
                 destination: URL(string: "https://carlineng.github.io/RadAlert/privacy.html")!)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
