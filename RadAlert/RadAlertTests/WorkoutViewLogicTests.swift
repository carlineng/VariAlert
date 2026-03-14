// SPDX-License-Identifier: MIT
//
//  WorkoutViewLogicTests.swift
//  RadAlertTests
//

import XCTest
import SwiftUI
import CoreBluetooth
@testable import RadAlert_Watch_App

final class WorkoutViewLogicTests: XCTestCase {

    // MARK: - formatElapsed

    func testFormatElapsedZero() {
        XCTAssertEqual(formatElapsed(0), "00:00")
    }

    func testFormatElapsedSeconds() {
        XCTAssertEqual(formatElapsed(45), "00:45")
    }

    func testFormatElapsedMinutesAndSeconds() {
        XCTAssertEqual(formatElapsed(90), "01:30")
        XCTAssertEqual(formatElapsed(3599), "59:59")
    }

    func testFormatElapsedHours() {
        XCTAssertEqual(formatElapsed(3600), "1:00:00")
        XCTAssertEqual(formatElapsed(3661), "1:01:01")
        XCTAssertEqual(formatElapsed(7384), "2:03:04")
    }

    // MARK: - RadarPillState.text

    func testPillTextConnected() {
        let state = RadarPillState(isConnected: true, isConnecting: false,
                                   isScanning: false, isDisconnectWarning: false)
        XCTAssertEqual(state.text, "Connected")
    }

    func testPillTextConnecting() {
        let state = RadarPillState(isConnected: false, isConnecting: true,
                                   isScanning: false, isDisconnectWarning: false)
        XCTAssertEqual(state.text, "Connecting")
    }

    func testPillTextSearching() {
        let state = RadarPillState(isConnected: false, isConnecting: false,
                                   isScanning: true, isDisconnectWarning: false)
        XCTAssertEqual(state.text, "Searching")
    }

    func testPillTextLost() {
        let state = RadarPillState(isConnected: false, isConnecting: false,
                                   isScanning: false, isDisconnectWarning: true)
        XCTAssertEqual(state.text, "Lost")
    }

    func testPillTextNoRadar() {
        let state = RadarPillState(isConnected: false, isConnecting: false,
                                   isScanning: false, isDisconnectWarning: false)
        XCTAssertEqual(state.text, "No Radar")
    }

    func testPillTextConnectedTakesPriority() {
        // Even if other flags are set, connected wins
        let state = RadarPillState(isConnected: true, isConnecting: true,
                                   isScanning: true, isDisconnectWarning: true)
        XCTAssertEqual(state.text, "Connected")
    }

    // MARK: - RadarPillState.dotColor

    func testPillDotColorConnected() {
        let state = RadarPillState(isConnected: true, isConnecting: false,
                                   isScanning: false, isDisconnectWarning: false)
        XCTAssertEqual(state.dotColor, .green)
    }

    func testPillDotColorConnecting() {
        let state = RadarPillState(isConnected: false, isConnecting: true,
                                   isScanning: false, isDisconnectWarning: false)
        XCTAssertEqual(state.dotColor, .yellow)
    }

    func testPillDotColorScanning() {
        let state = RadarPillState(isConnected: false, isConnecting: false,
                                   isScanning: true, isDisconnectWarning: false)
        XCTAssertEqual(state.dotColor, .yellow)
    }

    func testPillDotColorLost() {
        let state = RadarPillState(isConnected: false, isConnecting: false,
                                   isScanning: false, isDisconnectWarning: true)
        XCTAssertEqual(state.dotColor, .red)
    }

    func testPillDotColorNoRadar() {
        let state = RadarPillState(isConnected: false, isConnecting: false,
                                   isScanning: false, isDisconnectWarning: false)
        XCTAssertEqual(state.dotColor, .gray)
    }
}

// MARK: - WorkoutCoordinatorTests

final class WorkoutCoordinatorTests: XCTestCase {

    func makeManager() -> BluetoothManager {
        BluetoothManager(hapticProvider: MockHapticProvider(), radarStore: MockRadarStore())
    }

    func makeWSM() -> WorkoutSessionManager {
        WorkoutSessionManager(store: MockHealthStore())
    }

    // MARK: - Hold mechanic

    func testHoldProgressStartsAtZero() {
        let coordinator = WorkoutCoordinator()
        XCTAssertEqual(coordinator.holdProgress, 0)
    }

    func testHoldProgressIncrementsAfterStartHold() {
        let coordinator = WorkoutCoordinator()
        coordinator.startHold()
        let exp = expectation(description: "hold progress increments")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertGreaterThan(coordinator.holdProgress, 0)
            coordinator.cancelHold()
            exp.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testHoldProgressCapsAtOne() {
        let coordinator = WorkoutCoordinator()
        coordinator.startHold()
        let exp = expectation(description: "hold progress caps at 1")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertEqual(coordinator.holdProgress, 1.0, accuracy: 0.001)
            coordinator.cancelHold()
            exp.fulfill()
        }
        waitForExpectations(timeout: 2)
    }

    func testCancelHoldResetsProgressToZero() {
        let coordinator = WorkoutCoordinator()
        coordinator.startHold()
        let exp = expectation(description: "cancel resets progress")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            coordinator.cancelHold()
            XCTAssertEqual(coordinator.holdProgress, 0)
            exp.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testCompleteHoldResetsProgress() {
        let coordinator = WorkoutCoordinator()
        coordinator.startHold()
        let exp = expectation(description: "complete resets progress")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            coordinator.completeHold(bluetoothManager: self.makeManager())
            XCTAssertEqual(coordinator.holdProgress, 0)
            exp.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testCompleteHoldDisablesAlertsAndCallsOnHoldComplete() {
        let coordinator = WorkoutCoordinator()
        let manager = makeManager()
        manager.alertsEnabled = true
        var completeFired = false
        coordinator.onHoldComplete = { completeFired = true }

        coordinator.completeHold(bluetoothManager: manager)

        XCTAssertFalse(manager.alertsEnabled)
        XCTAssertTrue(completeFired)
    }

    // MARK: - Callback lifecycle

    func testRegisterWiresCallbacks() {
        let coordinator = WorkoutCoordinator()
        let manager = makeManager()
        let wsm = makeWSM()

        var threatFired = false
        var disconnectFired = false
        var expiredFired = false

        coordinator.register(
            bluetoothManager: manager, workoutManager: wsm,
            onThreatDetected: { threatFired = true },
            onDisconnected: { disconnectFired = true },
            onSessionExpired: { expiredFired = true }
        )

        manager.onNewThreatDetected?()
        manager.onRadarDisconnected?()
        wsm.onSessionExpired?()

        XCTAssertTrue(threatFired)
        XCTAssertTrue(disconnectFired)
        XCTAssertTrue(expiredFired)
    }

    func testTeardownClearsCallbacksAndHoldState() {
        let coordinator = WorkoutCoordinator()
        let manager = makeManager()
        let wsm = makeWSM()

        coordinator.register(bluetoothManager: manager, workoutManager: wsm,
                              onThreatDetected: {}, onDisconnected: {}, onSessionExpired: {})
        coordinator.startHold()
        coordinator.teardown(bluetoothManager: manager, workoutManager: wsm)

        XCTAssertNil(manager.onNewThreatDetected)
        XCTAssertNil(manager.onRadarDisconnected)
        XCTAssertNil(wsm.onSessionExpired)
        XCTAssertEqual(coordinator.holdProgress, 0)
    }
}

// MARK: - ContentViewRoutingTests

final class ContentViewRoutingTests: XCTestCase {

    func testOnboardingNotCompletedRoutesToOnboarding() {
        let dest = routeDestination(hasCompletedOnboarding: false, bluetoothState: .poweredOn,
                                    isAuthorized: true, isHealthKitAuthorized: true,
                                    appMode: .idle)
        XCTAssertEqual(dest, .onboarding)
    }

    func testBluetoothUnknownRoutesToBluetoothUnknown() {
        let dest = routeDestination(hasCompletedOnboarding: true, bluetoothState: .unknown,
                                    isAuthorized: true, isHealthKitAuthorized: true,
                                    appMode: .idle)
        XCTAssertEqual(dest, .bluetoothUnknown)
    }

    func testBluetoothNotAuthorizedRoutesToBluetoothDenied() {
        let dest = routeDestination(hasCompletedOnboarding: true, bluetoothState: .poweredOn,
                                    isAuthorized: false, isHealthKitAuthorized: true,
                                    appMode: .idle)
        XCTAssertEqual(dest, .bluetoothDenied)
    }

    func testHealthKitNotAuthorizedRoutesToHealthKitDenied() {
        let dest = routeDestination(hasCompletedOnboarding: true, bluetoothState: .poweredOn,
                                    isAuthorized: true, isHealthKitAuthorized: false,
                                    appMode: .idle)
        XCTAssertEqual(dest, .healthKitDenied)
    }

    func testIdleModeRoutesToIdle() {
        let dest = routeDestination(hasCompletedOnboarding: true, bluetoothState: .poweredOn,
                                    isAuthorized: true, isHealthKitAuthorized: true,
                                    appMode: .idle)
        XCTAssertEqual(dest, .idle)
    }

    func testWorkoutModeRoutesToWorkout() {
        let dest = routeDestination(hasCompletedOnboarding: true, bluetoothState: .poweredOn,
                                    isAuthorized: true, isHealthKitAuthorized: true,
                                    appMode: .workout)
        XCTAssertEqual(dest, .workout)
    }

    func testOnboardingTakesPriorityOverEverything() {
        // Not onboarded + bad bluetooth + no HK = onboarding wins
        let dest = routeDestination(hasCompletedOnboarding: false, bluetoothState: .unknown,
                                    isAuthorized: false, isHealthKitAuthorized: false,
                                    appMode: .workout)
        XCTAssertEqual(dest, .onboarding)
    }

    func testBluetoothUnknownTakesPriorityOverDenied() {
        let dest = routeDestination(hasCompletedOnboarding: true, bluetoothState: .unknown,
                                    isAuthorized: false, isHealthKitAuthorized: false,
                                    appMode: .idle)
        XCTAssertEqual(dest, .bluetoothUnknown)
    }

    func testBluetoothPoweredOffIsNotAuthorized() {
        // poweredOff → isAuthorized = (state != .unauthorized && state != .unsupported)
        // poweredOff counts as authorized (just not powered) — routing to idle/workout
        // This tests that poweredOff doesn't route to bluetoothDenied
        let dest = routeDestination(hasCompletedOnboarding: true, bluetoothState: .poweredOff,
                                    isAuthorized: true, isHealthKitAuthorized: true,
                                    appMode: .idle)
        XCTAssertEqual(dest, .idle)
    }
}
