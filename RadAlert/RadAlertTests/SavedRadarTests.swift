// SPDX-License-Identifier: MIT
//
//  SavedRadarTests.swift
//  RadAlertTests
//

import XCTest
@testable import RadAlert_Watch_App

final class SavedRadarTests: XCTestCase {

    private var store: UserDefaultsRadarStore!
    private var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "com.test.SavedRadarTests.\(UUID().uuidString)")!
        store = UserDefaultsRadarStore(defaults: testDefaults)
    }

    override func tearDown() {
        store.delete()
        testDefaults.removePersistentDomain(forName: testDefaults.volatileDomainNames.first ?? "")
        super.tearDown()
    }

    func testLoadReturnsNilWhenEmpty() {
        XCTAssertNil(store.load())
    }

    func testSaveAndLoadRoundTrip() {
        let id = UUID()
        let radar = SavedRadar(peripheralIdentifier: id,
                               displayName: "Varia RTL515",
                               identifierSuffix: "A4B2",
                               lastConnectedAt: nil)
        store.save(radar)

        let loaded = store.load()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.peripheralIdentifier, id)
        XCTAssertEqual(loaded?.displayName, "Varia RTL515")
        XCTAssertEqual(loaded?.identifierSuffix, "A4B2")
        XCTAssertNil(loaded?.lastConnectedAt)
    }

    func testSavePreservesLastConnectedAt() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let radar = SavedRadar(peripheralIdentifier: UUID(),
                               displayName: nil,
                               identifierSuffix: "ABCD",
                               lastConnectedAt: date)
        store.save(radar)

        let loaded = store.load()
        XCTAssertNotNil(loaded?.lastConnectedAt)
        XCTAssertEqual(loaded!.lastConnectedAt!.timeIntervalSince1970,
                       date.timeIntervalSince1970,
                       accuracy: 0.001)
    }

    func testDeleteClearsPersistence() {
        let radar = SavedRadar(peripheralIdentifier: UUID(),
                               displayName: "Varia",
                               identifierSuffix: "ABCD",
                               lastConnectedAt: nil)
        store.save(radar)
        XCTAssertNotNil(store.load())

        store.delete()
        XCTAssertNil(store.load())
    }

    func testCorruptedDataReturnsNil() {
        testDefaults.set(Data([0xFF, 0xFE, 0xFD]), forKey: "savedRadar")
        XCTAssertNil(store.load())
    }

    func testOverwriteUpdatesStoredRadar() {
        let first = SavedRadar(peripheralIdentifier: UUID(),
                               displayName: "First",
                               identifierSuffix: "AAAA",
                               lastConnectedAt: nil)
        let secondID = UUID()
        let second = SavedRadar(peripheralIdentifier: secondID,
                                displayName: "Second",
                                identifierSuffix: "BBBB",
                                lastConnectedAt: nil)
        store.save(first)
        store.save(second)

        let loaded = store.load()
        XCTAssertEqual(loaded?.peripheralIdentifier, secondID)
        XCTAssertEqual(loaded?.displayName, "Second")
    }
}
