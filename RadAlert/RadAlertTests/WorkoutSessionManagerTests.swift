// SPDX-License-Identifier: MIT
//
//  WorkoutSessionManagerTests.swift
//  RadAlertTests
//

import XCTest
import HealthKit
@testable import RadAlert_Watch_App

final class WorkoutSessionManagerTests: XCTestCase {

    func makeManager(authResult: Bool = true) -> (WorkoutSessionManager, MockHealthStore) {
        let store = MockHealthStore()
        store.requestAuthorizationResult = authResult
        let manager = WorkoutSessionManager(store: store)
        return (manager, store)
    }

    // MARK: - startWorkout (simulator path)

    func testStartWorkoutSetsWorkoutStartDate() {
        let (manager, _) = makeManager()
        let exp = expectation(description: "workout started")

        manager.startWorkout { success in
            XCTAssertTrue(success)
            XCTAssertNotNil(manager.workoutStartDate)
            exp.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testStartWorkoutCalledTwiceStillSucceeds() {
        let (manager, _) = makeManager()
        let exp = expectation(description: "second start")

        manager.startWorkout { _ in
            manager.startWorkout { success in
                XCTAssertTrue(success)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 2)
    }

    // MARK: - endAndSave (simulator path)

    func testEndAndSaveClearsWorkoutStartDate() {
        let (manager, _) = makeManager()
        manager.workoutStartDate = Date()
        let exp = expectation(description: "end and save")

        manager.endAndSave {
            XCTAssertNil(manager.workoutStartDate)
            exp.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    // MARK: - endAndDiscard (simulator path)

    func testEndAndDiscardClearsWorkoutStartDate() {
        let (manager, _) = makeManager()
        manager.workoutStartDate = Date()
        let exp = expectation(description: "end and discard")

        manager.endAndDiscard {
            XCTAssertNil(manager.workoutStartDate)
            exp.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    // MARK: - handleSessionStateChange

    func testUnexpectedEndCallsOnSessionExpired() {
        let (manager, _) = makeManager()
        var expired = false
        manager.onSessionExpired = { expired = true }

        manager.handleSessionStateChange(to: .ended)

        XCTAssertTrue(expired)
        XCTAssertNil(manager.workoutStartDate)
    }

    func testIntentionalEndDoesNotCallOnSessionExpired() {
        let (manager, _) = makeManager()
        var expired = false
        manager.onSessionExpired = { expired = true }
        manager.intentionalEnd = true

        manager.handleSessionStateChange(to: .ended)

        XCTAssertFalse(expired)
    }

    func testHandleSessionStateChangeResetsIntentionalEndFlag() {
        let (manager, _) = makeManager()
        manager.intentionalEnd = true

        manager.handleSessionStateChange(to: .ended)

        XCTAssertFalse(manager.intentionalEnd)
    }

    func testNonEndedStateDoesNotTriggerExpiry() {
        let (manager, _) = makeManager()
        var expired = false
        manager.onSessionExpired = { expired = true }

        manager.handleSessionStateChange(to: .running)
        manager.handleSessionStateChange(to: .stopped)

        XCTAssertFalse(expired)
    }

    // MARK: - requestAuthorization (routes through injected store — no simulator guard)

    func testRequestAuthorizationGrantedReturnsTrue() {
        let (manager, _) = makeManager(authResult: true)
        let exp = expectation(description: "auth granted")

        manager.requestAuthorization { success in
            XCTAssertTrue(success)
            exp.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testRequestAuthorizationDeniedReturnsFalse() {
        let (manager, _) = makeManager(authResult: false)
        let exp = expectation(description: "auth denied")

        manager.requestAuthorization { success in
            XCTAssertFalse(success)
            exp.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testRequestAuthorizationPropagatesError() {
        let (manager, store) = makeManager(authResult: false)
        struct FakeError: Error {}
        store.requestAuthorizationError = FakeError()
        let exp = expectation(description: "auth error")

        manager.requestAuthorization { success in
            XCTAssertFalse(success)
            exp.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
}
