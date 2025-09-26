// SPDX-License-Identifier: MIT
//
//  HapticTestView.swift
//  VariAlertWatch Watch App
//
//  Created by Carlin Eng on 2/10/25.
//

import SwiftUI
import WatchKit

struct HapticTestView: View {
    let hapticTypes: [(String, WKHapticType)] = [
        ("Retry", .retry),
        ("Success", .success),
        ("Notification", .notification),
        ("Click", .click),
        ("Failure", .failure),
        ("navigationGeneric", .navigationGenericManeuver),
        ("nagivationLeftTurn", .navigationLeftTurn),
        ("navigationRightTurn", .navigationRightTurn),
        ("underwaterDepthPrompt", .underwaterDepthPrompt),
        ("underwaterDepthCriticalPrompt", .underwaterDepthCriticalPrompt)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Haptic Tester")
                    .font(.headline)
                
                ForEach(hapticTypes, id: \.0) { haptic in
                    Button(action: {
                        WKInterfaceDevice.current().play(haptic.1)
                    }) {
                        Text(haptic.0)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
    }
}
