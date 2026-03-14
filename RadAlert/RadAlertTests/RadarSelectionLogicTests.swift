// SPDX-License-Identifier: MIT
//
//  RadarSelectionLogicTests.swift
//  RadAlertTests
//

import XCTest
import SwiftUI
@testable import RadAlert_Watch_App

final class RadarSelectionLogicTests: XCTestCase {

    // MARK: - singleDevice

    func testSingleDeviceReturnsNilForEmptyList() {
        XCTAssertNil(RadarSelectionView.singleDevice(from: []))
    }

    func testSingleDeviceReturnsDeviceForOneElement() {
        let device = DiscoveredRadar(id: UUID(), name: "Varia", rssi: -60,
                                     identifierSuffix: "ABCD", isSaved: false)
        let result = RadarSelectionView.singleDevice(from: [device])
        XCTAssertEqual(result?.id, device.id)
    }

    func testSingleDeviceReturnsNilForMultipleDevices() {
        let d1 = DiscoveredRadar(id: UUID(), name: "Varia 1", rssi: -60,
                                  identifierSuffix: "AAAA", isSaved: false)
        let d2 = DiscoveredRadar(id: UUID(), name: "Varia 2", rssi: -70,
                                  identifierSuffix: "BBBB", isSaved: false)
        XCTAssertNil(RadarSelectionView.singleDevice(from: [d1, d2]))
    }

    // MARK: - rssiColor

    func testRssiColorStrongSignal() {
        // rssi > -60 → green
        XCTAssertEqual(rssiColor(-55), .green)
        XCTAssertEqual(rssiColor(-59), .green)
        XCTAssertEqual(rssiColor(0), .green)
    }

    func testRssiColorModerateSignal() {
        // -75 < rssi <= -60 → yellow
        XCTAssertEqual(rssiColor(-60), .yellow)
        XCTAssertEqual(rssiColor(-70), .yellow)
        XCTAssertEqual(rssiColor(-74), .yellow)
    }

    func testRssiColorWeakSignal() {
        // rssi <= -75 → orange
        XCTAssertEqual(rssiColor(-75), .orange)
        XCTAssertEqual(rssiColor(-90), .orange)
        XCTAssertEqual(rssiColor(-100), .orange)
    }

    func testRssiColorBoundary() {
        XCTAssertEqual(rssiColor(-75), .orange)
        XCTAssertEqual(rssiColor(-76), .orange)
    }
}
