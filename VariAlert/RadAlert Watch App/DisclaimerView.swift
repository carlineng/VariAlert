// SPDX-License-Identifier: MIT
//
//  DisclaimerView.swift
//  RadAlert Watch App
//

import SwiftUI

struct DisclaimerView: View {
    @AppStorage("hasAcknowledgedDisclaimer") private var hasAcknowledged = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Safety Notice")
                    .font(.headline)

                Text("RadAlert supplements your awareness of approaching vehicles. It is **not** a certified safety device and cannot guarantee detection of all vehicles.")
                    .font(.caption)

                Text("Always follow traffic laws and rely on your own judgement. The app may miss vehicles or produce false alerts.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("I Understand") {
                    hasAcknowledged = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            }
            .padding()
        }
    }
}
