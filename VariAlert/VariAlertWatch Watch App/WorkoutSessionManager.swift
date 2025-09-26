// SPDX-License-Identifier: MIT
//
//  WorkoutSessionManager.swift
//  VariAlertWatch Watch App
//
//  Created by Carlin Eng on 2/3/25.
//

import HealthKit
import SwiftUI

class WorkoutSessionManager: NSObject, ObservableObject {
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?

    func startWorkout() {
        
        let typesToShare: Set = [HKObjectType.workoutType()]
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if let error = error {
                print("Error requesting HealthKit authorization: \(error.localizedDescription)")
                return
            }
            
            guard success else {
                print("HealthKit authorization was not granted.")
                return
            }
            
            // Configure a workout session for 'Other' type (or 'Cycling' if appropriate).
            let configuration = HKWorkoutConfiguration()
            configuration.activityType = .cycling  // or .other
            configuration.locationType = .outdoor
            
            do {
                self.workoutSession = try HKWorkoutSession(healthStore: self.healthStore, configuration: configuration)
                self.workoutBuilder = self.workoutSession?.associatedWorkoutBuilder()
                
                // Link session & builder
                self.workoutSession?.delegate = self
                self.workoutBuilder?.delegate = self
                
                // Start the session
                self.workoutSession?.startActivity(with: Date())
                self.workoutBuilder?.beginCollection(withStart: Date()) { (success, error) in
                    if let error = error {
                        print("Error beginning workout collection: \(error.localizedDescription)")
                    }
                }
                
                print("Workout session started.")
            } catch {
                print("Failed to start workout session: \(error.localizedDescription)")
            }
        }
    }

    func stopWorkout() {
        guard let session = workoutSession else { return }

        // Mark the end of the workout
        session.end()
        workoutBuilder?.endCollection(withEnd: Date()) { (success, error) in
            if let error = error {
                print("Error ending workout collection: \(error.localizedDescription)")
            }
            print("Workout session ended.")
        }
    }
}

extension WorkoutSessionManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running:
            print("Workout session is running.")
        case .ended:
            print("Workout session ended.")
        default:
            break
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent) {
        // Handle events if needed
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error.localizedDescription)")
    }
}

extension WorkoutSessionManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        print("Workout builder collected data: \(collectedTypes)")
    }
}
