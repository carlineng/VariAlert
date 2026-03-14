// SPDX-License-Identifier: MIT
//
//  RadarDataParsingTests.swift
//  RadAlertTests
//

import XCTest
@testable import RadAlert_Watch_App

final class RadarDataParsingTests: XCTestCase {

    // MARK: - parseRadarData

    func testSingleByteReturnsEmptyArray() {
        let data = Data([0x01])
        let result = parseRadarData(data)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, [])
    }

    func testInvalidLengthTwoBytes() {
        let data = Data([0x01, 0x02])
        XCTAssertNil(parseRadarData(data))
    }

    func testInvalidLengthThreeBytes() {
        let data = Data([0x01, 0x02, 0x03])
        XCTAssertNil(parseRadarData(data))
    }

    func testInvalidLengthNotMultipleOfThreePlusOne() {
        // 5 bytes: (5-1) % 3 == 1, not 0 → invalid
        let data = Data([0x10, 0x01, 0x32, 0x1E, 0x05])
        XCTAssertNil(parseRadarData(data))
    }

    func testValidSingleThreatPacket() {
        // Header + 1 threat (3 bytes): total 4 bytes
        let data = Data([0x10, 0x05, 0x32, 0x1E])
        let result = parseRadarData(data)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.count, 1)
        XCTAssertEqual(result![0].id, 0x05)
        XCTAssertEqual(result![0].distance, 0x32)  // 50
        XCTAssertEqual(result![0].speed, 0x1E)     // 30
    }

    func testValidTwoThreatPacket() {
        // Header + 2 threats (6 bytes): total 7 bytes
        let data = Data([0x20, 0x01, 0x28, 0x14, 0x02, 0x3C, 0x1E])
        let result = parseRadarData(data)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.count, 2)
        XCTAssertEqual(result![0].id, 0x01)
        XCTAssertEqual(result![0].distance, 0x28)  // 40
        XCTAssertEqual(result![0].speed, 0x14)     // 20
        XCTAssertEqual(result![1].id, 0x02)
        XCTAssertEqual(result![1].distance, 0x3C)  // 60
        XCTAssertEqual(result![1].speed, 0x1E)     // 30
    }

    func testEmptyDataIsInvalid() {
        XCTAssertNil(parseRadarData(Data()))
    }

    // MARK: - handleThreats

    func testNewThreatIncrementsVehicleCount() {
        let manager = BluetoothManager(hapticProvider: MockHapticProvider(),
                                       radarStore: MockRadarStore())
        manager.handleThreats([Threat(id: 1, distance: 50, speed: 30)])
        XCTAssertEqual(manager.vehicleCount, 1)
    }

    func testRepeatedThreatIDDoesNotIncrement() {
        let manager = BluetoothManager(hapticProvider: MockHapticProvider(),
                                       radarStore: MockRadarStore())
        manager.handleThreats([Threat(id: 1, distance: 50, speed: 30)])
        manager.handleThreats([Threat(id: 1, distance: 45, speed: 28)])
        XCTAssertEqual(manager.vehicleCount, 1)
    }

    func testMultipleNewThreatsCountedTogether() {
        let manager = BluetoothManager(hapticProvider: MockHapticProvider(),
                                       radarStore: MockRadarStore())
        manager.handleThreats([
            Threat(id: 1, distance: 50, speed: 30),
            Threat(id: 2, distance: 40, speed: 25)
        ])
        XCTAssertEqual(manager.vehicleCount, 2)
    }

    func testAlertsDisabledCountsButSkipsHaptic() {
        let haptic = MockHapticProvider()
        let manager = BluetoothManager(hapticProvider: haptic, radarStore: MockRadarStore())
        manager.alertsEnabled = false

        manager.handleThreats([Threat(id: 1, distance: 50, speed: 30)])

        XCTAssertEqual(manager.vehicleCount, 1)
        XCTAssertNil(manager.lastThreatHapticAt, "No haptic should fire when alertsEnabled is false")
    }

    func testHapticCooldownSuppressesImmediateRepeat() {
        let haptic = MockHapticProvider()
        let manager = BluetoothManager(hapticProvider: haptic, radarStore: MockRadarStore())

        // First new threat — haptic fires
        manager.handleThreats([Threat(id: 1, distance: 50, speed: 30)])
        XCTAssertNotNil(manager.lastThreatHapticAt)

        let firstFire = manager.lastThreatHapticAt

        // Second new threat immediately — cooldown should suppress
        manager.handleThreats([Threat(id: 2, distance: 40, speed: 25)])
        XCTAssertEqual(manager.lastThreatHapticAt, firstFire,
                       "lastThreatHapticAt should not advance — haptic suppressed by cooldown")
    }

    func testHapticFiresAfterCooldownExpires() {
        let haptic = MockHapticProvider()
        let manager = BluetoothManager(hapticProvider: haptic, radarStore: MockRadarStore())

        manager.handleThreats([Threat(id: 1, distance: 50, speed: 30)])
        let firstFire = manager.lastThreatHapticAt!

        // Manually backdate lastThreatHapticAt to simulate cooldown expiry
        manager.lastThreatHapticAt = firstFire.addingTimeInterval(-2.0)

        manager.handleThreats([Threat(id: 2, distance: 40, speed: 25)])
        XCTAssertNotEqual(manager.lastThreatHapticAt, manager.lastThreatHapticAt.map { _ in firstFire },
                          "New haptic should fire after cooldown expires")
        XCTAssertGreaterThan(manager.lastThreatHapticAt!, firstFire.addingTimeInterval(-2.0))
    }
}

