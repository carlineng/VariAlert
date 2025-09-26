// SPDX-License-Identifier: MIT
//
//  WatchConnectivityManager.swift
//  VariAlertWatch Watch App
//
//  Created by Carlin Eng on 2/2/25.
//

import WatchConnectivity
import Combine
import SwiftUI

class WatchConnectivityManager: NSObject, ObservableObject {
    // MARK: - Properties
    private var session: WCSession?
    private var appState: WatchAppState  // Track the app's current mode

    init(appState: WatchAppState) {
        self.appState = appState
        super.init()
        setupSession()
    }
    
    // MARK: - Setup
    private func setupSession() {
        // Check if WatchConnectivity is supported
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // MARK: - Methods
    
    /// Example method to respond to an incoming message from iPhone
    func handleIncomingMessage(_ message: [String: Any]) {
        
        guard appState.mode == .workout else {
            print("Haptic alert skipped: App is in Idle mode")
            return
        }

        // Parse the dictionary for "alert": "car_detected" or similar
        if let alert = message["alert"] as? String, alert == "car_detected" {
            for i in 0..<4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + (0.3 * Double(i))) {
                    WKInterfaceDevice.current().play(.retry)
                }
            }
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error = error {
            print("Watch session activation failed: \(error.localizedDescription)")
        } else {
            print("Watch session activated.")
        }
    }
        
    // For receiving messages from iPhone in real time
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Watch received message: \(message)")
        handleIncomingMessage(message)
    }
}
