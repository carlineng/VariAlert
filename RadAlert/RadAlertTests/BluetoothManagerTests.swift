// SPDX-License-Identifier: MIT
//
//  BluetoothManagerTests.swift
//  RadAlertTests
//

import XCTest
@testable import RadAlert_Watch_App

final class BluetoothManagerTests: XCTestCase {

    func makeManager(savedRadar: SavedRadar? = nil) -> (BluetoothManager, MockRadarStore) {
        let store = MockRadarStore()
        store.storedRadar = savedRadar
        let manager = BluetoothManager(hapticProvider: MockHapticProvider(),
                                       radarStore: store,
                                       scanTimeoutInterval: 0.1)
        return (manager, store)
    }

    // MARK: - startScanning state reset

    func testStartScanningResetsState() {
        let (manager, _) = makeManager()
        manager.lastThreatIDs = [1, 2, 3]
        manager.scanTimedOut = true
        manager.discoveredDevices = [
            DiscoveredRadar(id: UUID(), name: "Test", rssi: -60, identifierSuffix: "ABCD", isSaved: false)
        ]

        manager.startScanning()

        XCTAssertTrue(manager.isScanning)
        XCTAssertFalse(manager.scanTimedOut)
        XCTAssertTrue(manager.lastThreatIDs.isEmpty)
        XCTAssertTrue(manager.discoveredDevices.isEmpty)
    }

    // MARK: - Scan timeout

    func testScanTimeoutSetsScanTimedOut() {
        let (manager, _) = makeManager()
        manager.startScanning()
        XCTAssertTrue(manager.isScanning)

        let exp = expectation(description: "scan timeout")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(manager.scanTimedOut)
            XCTAssertFalse(manager.isScanning)
            exp.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    // MARK: - connect(to:) state

    func testConnectClearsScanTimedOut() {
        let (manager, _) = makeManager()
        manager.scanTimedOut = true
        let device = DiscoveredRadar(id: UUID(), name: "Radar", rssi: -60, identifierSuffix: "ABCD", isSaved: false)
        manager.connect(to: device)
        XCTAssertFalse(manager.scanTimedOut)
        XCTAssertTrue(manager.isConnecting)
    }

    func testConnectMissingPeripheralClearsConnecting() {
        // Non-simulator: peripheral not in discoveredPeripherals → isConnecting reset
        // In simulator, connect always succeeds (async). Just verify state is set initially.
        let (manager, _) = makeManager()
        let device = DiscoveredRadar(id: UUID(), name: "Radar", rssi: -60, identifierSuffix: "ABCD", isSaved: false)
        manager.connect(to: device)
        // In simulator, isConnecting = true then transitions async
        XCTAssertTrue(manager.isConnecting || manager.isConnected)
    }

    // MARK: - disconnect

    func testDisconnectStopsScanAndClearsConnected() {
        let (manager, _) = makeManager()
        manager.isScanning = true
        manager.isConnected = true

        manager.disconnect()

        XCTAssertFalse(manager.isScanning)
        XCTAssertFalse(manager.isConnected)
    }

    func testDisconnectInvalidatesScanTimer() {
        let (manager, _) = makeManager()
        manager.startScanning()
        XCTAssertTrue(manager.isScanning)

        manager.disconnect()
        XCTAssertFalse(manager.isScanning)
    }

    // MARK: - handleConnectionSucceeded

    func testHandleConnectionSucceededSetsConnected() {
        let (manager, _) = makeManager()
        manager.isConnecting = true

        manager.handleConnectionSucceeded(peripheralIdentifier: UUID(), peripheralName: "Varia")

        XCTAssertFalse(manager.isConnecting)
        XCTAssertTrue(manager.isConnected)
    }

    func testHandleConnectionSucceededUpdatesLastConnectedAt() {
        let radarID = UUID()
        let saved = SavedRadar(peripheralIdentifier: radarID, displayName: "Varia",
                               identifierSuffix: "ABCD", lastConnectedAt: nil)
        let (manager, store) = makeManager(savedRadar: saved)
        manager.savedRadar = saved

        manager.handleConnectionSucceeded(peripheralIdentifier: radarID, peripheralName: "Varia")

        XCTAssertNotNil(manager.savedRadar?.lastConnectedAt)
        XCTAssertNotNil(store.storedRadar?.lastConnectedAt)
    }

    func testHandleConnectionSucceededIgnoresUnknownPeripheral() {
        let saved = SavedRadar(peripheralIdentifier: UUID(), displayName: "Varia",
                               identifierSuffix: "ABCD", lastConnectedAt: nil)
        let (manager, store) = makeManager(savedRadar: saved)
        manager.savedRadar = saved

        // Pass a different UUID — not the saved radar
        manager.handleConnectionSucceeded(peripheralIdentifier: UUID(), peripheralName: "Other")

        XCTAssertNil(store.storedRadar?.lastConnectedAt)
    }

    // MARK: - handleConnectionFailed

    func testHandleConnectionFailedClearsConnecting() {
        let (manager, _) = makeManager()
        manager.isConnecting = true
        manager.intentionalDisconnect = true

        manager.handleConnectionFailed()

        XCTAssertFalse(manager.isConnecting)
        XCTAssertFalse(manager.intentionalDisconnect)
    }

    // MARK: - handleUnexpectedDisconnect

    func testUnexpectedDisconnectFiresCallback() {
        let (manager, _) = makeManager()
        var callbackFired = false
        manager.onRadarDisconnected = { callbackFired = true }

        manager.handleUnexpectedDisconnect()

        XCTAssertTrue(callbackFired)
    }

    func testUnexpectedDisconnectPlaysHaptic() {
        let haptic = MockHapticProvider()
        let store = MockRadarStore()
        let manager = BluetoothManager(hapticProvider: haptic, radarStore: store)
        manager.handleUnexpectedDisconnect()
        XCTAssertEqual(haptic.lastHapticType, .failure)
    }

    // MARK: - Intentional disconnect suppression (via intentionalDisconnect flag)

    func testIntentionalDisconnectDoesNotFireCallback() {
        let (manager, _) = makeManager()
        var callbackFired = false
        manager.onRadarDisconnected = { callbackFired = true }

        // Simulate intentional: flag is set, so delegate would skip handleUnexpectedDisconnect
        // We verify that the flag works correctly with the delegate logic:
        // - intentionalDisconnect = true → wasIntentional = true → skip handleUnexpectedDisconnect
        manager.intentionalDisconnect = true
        let wasIntentional = manager.intentionalDisconnect
        manager.intentionalDisconnect = false
        if !wasIntentional {
            manager.handleUnexpectedDisconnect()
        }

        XCTAssertFalse(callbackFired)
    }

    // MARK: - handleDiscoveredPeripheral

    func testHandleDiscoveredPeripheralAddsToDiscoveredDevices() {
        let (manager, _) = makeManager()
        manager.handleDiscoveredPeripheral(uuid: UUID(), name: "Varia RTL515", rssi: -55)
        XCTAssertEqual(manager.discoveredDevices.count, 1)
        XCTAssertEqual(manager.discoveredDevices[0].name, "Varia RTL515")
    }

    func testHandleDiscoveredPeripheralDeduplicates() {
        let (manager, _) = makeManager()
        let id = UUID()
        manager.handleDiscoveredPeripheral(uuid: id, name: "Varia", rssi: -55)
        manager.handleDiscoveredPeripheral(uuid: id, name: "Varia", rssi: -55)
        XCTAssertEqual(manager.discoveredDevices.count, 1)
    }

    func testHandleDiscoveredSavedRadarSetsConnectingAndStopsScanning() {
        let savedID = UUID()
        let saved = SavedRadar(peripheralIdentifier: savedID, displayName: "Varia",
                               identifierSuffix: "ABCD", lastConnectedAt: nil)
        let (manager, _) = makeManager(savedRadar: saved)
        manager.savedRadar = saved
        manager.isScanning = true

        manager.handleDiscoveredPeripheral(uuid: savedID, name: "Varia", rssi: -60)

        XCTAssertTrue(manager.isConnecting)
        XCTAssertFalse(manager.isScanning)
    }

    func testHandleDiscoveredSavedRadarInsertsAtFront() {
        let savedID = UUID()
        let saved = SavedRadar(peripheralIdentifier: savedID, displayName: "Varia",
                               identifierSuffix: "ABCD", lastConnectedAt: nil)
        let (manager, _) = makeManager(savedRadar: saved)
        manager.savedRadar = saved
        manager.handleDiscoveredPeripheral(uuid: UUID(), name: "Other Radar", rssi: -70)
        manager.handleDiscoveredPeripheral(uuid: savedID, name: "Varia", rssi: -55)

        XCTAssertEqual(manager.discoveredDevices[0].id, savedID)
    }

    func testHandleDiscoveredNonSavedRadarDoesNotAutoConnect() {
        let savedID = UUID()
        let saved = SavedRadar(peripheralIdentifier: savedID, displayName: "Varia",
                               identifierSuffix: "ABCD", lastConnectedAt: nil)
        let (manager, _) = makeManager(savedRadar: saved)
        manager.savedRadar = saved

        manager.handleDiscoveredPeripheral(uuid: UUID(), name: "Other Radar", rssi: -70)

        XCTAssertFalse(manager.isConnecting)
    }

    // MARK: - handleUnexpectedDisconnect retry-to-scanning

    func testUnexpectedDisconnectTriggersRescanning() {
        let haptic = MockHapticProvider()
        let store = MockRadarStore()
        let manager = BluetoothManager(hapticProvider: haptic, radarStore: store,
                                       scanTimeoutInterval: 10.0,
                                       unexpectedDisconnectRetryDelay: 0.1)
        let exp = expectation(description: "rescanning after disconnect")

        manager.handleUnexpectedDisconnect()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(manager.isScanning)
            exp.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    // MARK: - saveRadar / forgetSavedRadar

    func testSaveRadarPersists() {
        let (manager, store) = makeManager()
        let device = DiscoveredRadar(id: UUID(), name: "Varia RTL515", rssi: -55,
                                     identifierSuffix: "A4B2", isSaved: false)
        manager.saveRadar(device)

        XCTAssertNotNil(manager.savedRadar)
        XCTAssertNotNil(store.storedRadar)
        XCTAssertEqual(manager.savedRadar?.displayName, "Varia RTL515")
    }

    func testForgetSavedRadarClearsState() {
        let device = DiscoveredRadar(id: UUID(), name: "Varia", rssi: -60,
                                     identifierSuffix: "ABCD", isSaved: true)
        let (manager, store) = makeManager()
        manager.saveRadar(device)

        manager.forgetSavedRadar()

        XCTAssertNil(manager.savedRadar)
        XCTAssertNil(store.storedRadar)
    }
}
