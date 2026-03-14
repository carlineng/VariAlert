// SPDX-License-Identifier: MIT
//
//  HealthStoreProviding.swift
//  RadAlert Watch App
//

import HealthKit

protocol HealthStoreProviding {
    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus
    func requestAuthorization(toShare typesToShare: Set<HKSampleType>,
                              read typesToRead: Set<HKObjectType>,
                              completion: @escaping (Bool, Error?) -> Void)
}

/// Production implementation — thin wrapper around HKHealthStore.
/// Exposing `healthStore` lets WorkoutSessionManager create HKWorkoutSessions.
struct RealHealthStore: HealthStoreProviding {
    let healthStore: HKHealthStore

    init() { self.healthStore = HKHealthStore() }

    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        healthStore.authorizationStatus(for: type)
    }

    func requestAuthorization(toShare typesToShare: Set<HKSampleType>,
                              read typesToRead: Set<HKObjectType>,
                              completion: @escaping (Bool, Error?) -> Void) {
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead, completion: completion)
    }
}
