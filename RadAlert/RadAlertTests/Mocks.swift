// SPDX-License-Identifier: MIT
//
//  Mocks.swift
//  RadAlertTests
//

import Foundation
import HealthKit
import WatchKit
@testable import RadAlert_Watch_App

// MARK: - MockHapticProvider

class MockHapticProvider: HapticProviding {
    private(set) var playCount = 0
    private(set) var lastHapticType: WKHapticType?

    func play(_ hapticType: WKHapticType) {
        playCount += 1
        lastHapticType = hapticType
    }

    func reset() {
        playCount = 0
        lastHapticType = nil
    }
}

// MARK: - MockRadarStore

class MockRadarStore: RadarStoreProviding {
    var storedRadar: SavedRadar?

    func load() -> SavedRadar? { storedRadar }
    func save(_ radar: SavedRadar) { storedRadar = radar }
    func delete() { storedRadar = nil }
}

// MARK: - MockHealthStore

class MockHealthStore: HealthStoreProviding {
    var authorizationStatusResult: HKAuthorizationStatus = .notDetermined
    var requestAuthorizationResult: Bool = true
    var requestAuthorizationError: Error? = nil

    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        authorizationStatusResult
    }

    func requestAuthorization(toShare typesToShare: Set<HKSampleType>,
                               read typesToRead: Set<HKObjectType>,
                               completion: @escaping (Bool, Error?) -> Void) {
        completion(requestAuthorizationResult, requestAuthorizationError)
    }
}
