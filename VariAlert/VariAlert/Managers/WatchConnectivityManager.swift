// SPDX-License-Identifier: MIT
//
//  WatchConnectivityManager.swift
//  VariAlert
//
//  Created by Carlin Eng on 2/2/25.
//

import Foundation
import WatchConnectivity
import Combine

class WatchConnectivityManager: NSObject, ObservableObject {
    // MARK: - Singleton
    static let shared = WatchConnectivityManager()
    
    // MARK: - Properties
    private var session: WCSession?
        
    override init() {
        super.init()
        setupSession()
    }
    
    // MARK: - Setup
    private func setupSession() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // MARK: - Public Methods
    
    /// Send a message to the watch to trigger a haptic feedback or local notification
    func sendCarDetectedAlert() {
        print("Sending car-detected message to the Watch...")

        guard let session = session, session.isReachable else {
            print("Watch session not reachable or not initialized.")
            return
        }

        let message: [String: Any] = ["alert": "car_detected"]
        session.sendMessage(message, replyHandler: nil) { error in
            print("Error sending message: \(error.localizedDescription)")
        }
    }
    /// Optionally handle other watch-related communication (e.g. watch -> phone).
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        // Re-activate if needed
        session.activate()
    }
    func sessionWatchStateDidChange(_ session: WCSession) {}
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if let error = error {
            print("Watch session activation failed: \(error.localizedDescription)")
        } else {
            print("Watch session activated.")
        }
    }
    
    // If watch sends message to phone
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Received message from watch: \(message)")
    }
}
