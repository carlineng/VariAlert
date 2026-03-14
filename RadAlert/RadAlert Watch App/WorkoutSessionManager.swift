// SPDX-License-Identifier: MIT
//
//  WorkoutSessionManager.swift
//  RadAlert Watch App
//
//  Created by Carlin Eng on 2/3/25.
//

import HealthKit
import SwiftUI

class WorkoutSessionManager: NSObject, ObservableObject {
    private let store: HealthStoreProviding
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    // internal (not private) so tests can set it directly
    var intentionalEnd = false

    @Published var workoutStartDate: Date?
    var onSessionExpired: (() -> Void)?

    var isHealthKitAuthorized: Bool {
#if targetEnvironment(simulator)
        return true
#else
        return store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized
#endif
    }

    init(store: HealthStoreProviding = RealHealthStore()) {
        self.store = store
        super.init()
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let typesToShare: Set = [HKObjectType.workoutType()]
        let typesToRead: Set<HKObjectType> = []
        store.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if let error = error {
                print("Error requesting HealthKit authorization: \(error.localizedDescription)")
            }
            DispatchQueue.main.async { completion(success) }
        }
    }

    func startWorkout(completion: @escaping (Bool) -> Void) {
#if targetEnvironment(simulator)
        print("[Simulator] Workout session started.")
        DispatchQueue.main.async {
            self.workoutStartDate = Date()
            completion(true)
        }
#else
        requestAuthorization { success in
            guard success else {
                print("HealthKit authorization was not granted.")
                DispatchQueue.main.async { completion(false) }
                return
            }
            self.beginSession(completion: completion)
        }
#endif
    }

    private func beginSession(completion: @escaping (Bool) -> Void) {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .cycling
        configuration.locationType = .outdoor

        guard let realStore = store as? RealHealthStore else {
            print("beginSession requires RealHealthStore.")
            DispatchQueue.main.async { completion(false) }
            return
        }

        do {
            workoutSession = try HKWorkoutSession(healthStore: realStore.healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()

            workoutSession?.delegate = self
            workoutBuilder?.delegate = self

            let startDate = Date()
            workoutSession?.startActivity(with: startDate)
            workoutBuilder?.beginCollection(withStart: startDate) { _, error in
                if let error = error {
                    print("Error beginning workout collection: \(error.localizedDescription)")
                    DispatchQueue.main.async { completion(false) }
                    return
                }
                DispatchQueue.main.async { completion(true) }
            }

            DispatchQueue.main.async {
                self.workoutStartDate = startDate
            }
            print("Workout session started.")
        } catch {
            print("Failed to start workout session: \(error.localizedDescription)")
            DispatchQueue.main.async { completion(false) }
        }
    }

    func endAndSave(completion: @escaping () -> Void) {
#if targetEnvironment(simulator)
        print("[Simulator] Workout saved.")
        DispatchQueue.main.async { self.workoutStartDate = nil; completion() }
#else
        guard let session = workoutSession else { completion(); return }
        intentionalEnd = true
        if session.state != .ended {
            session.end()
        }
        workoutBuilder?.endCollection(withEnd: Date()) { _, error in
            if let error = error {
                print("Error ending workout collection: \(error.localizedDescription)")
            }
            self.workoutBuilder?.finishWorkout { _, error in
                if let error = error {
                    print("Error saving workout: \(error.localizedDescription)")
                }
                print("Workout saved.")
                DispatchQueue.main.async {
                    self.workoutStartDate = nil
                    completion()
                }
            }
        }
#endif
    }

    func endAndDiscard(completion: @escaping () -> Void) {
#if targetEnvironment(simulator)
        print("[Simulator] Workout discarded.")
        DispatchQueue.main.async { self.workoutStartDate = nil; completion() }
#else
        guard let session = workoutSession else { completion(); return }
        intentionalEnd = true
        if session.state != .ended {
            session.end()
        }
        workoutBuilder?.endCollection(withEnd: Date()) { _, error in
            if let error = error {
                print("Error ending workout collection: \(error.localizedDescription)")
            }
            self.workoutBuilder?.discardWorkout()
            print("Workout discarded.")
            DispatchQueue.main.async {
                self.workoutStartDate = nil
                completion()
            }
        }
#endif
    }

    // MARK: - Internal session state handler (called from delegate; internal for testing)

    func handleSessionStateChange(to state: HKWorkoutSessionState) {
        if state == .ended {
            if !intentionalEnd {
                workoutStartDate = nil
                onSessionExpired?()
            }
            intentionalEnd = false
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
            DispatchQueue.main.async {
                self.handleSessionStateChange(to: toState)
            }
        default:
            break
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent) {}

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error.localizedDescription)")
    }
}

extension WorkoutSessionManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        print("Workout builder collected data: \(collectedTypes)")
    }
}
