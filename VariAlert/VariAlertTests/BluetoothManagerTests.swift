// SPDX-License-Identifier: MIT
//
//  BluetoothManagerTests.swift
//  VariAlertTests
//
//  Created by Carlin Eng on 2/6/25.
//

import XCTest
import CoreBluetooth
@testable import VariAlert

class BluetoothManagerTests: XCTestCase {
    var bluetoothManager: BluetoothManager!
    var mockCentralManager: MockCentralManager!

    override func setUp() {
        super.setUp()
        mockCentralManager = MockCentralManager()
        bluetoothManager = BluetoothManager(centralManager: mockCentralManager)
    }

    override func tearDown() {
        bluetoothManager = nil
        mockCentralManager = nil
        super.tearDown()
    }
    
    // Test Bluetooth State Handling
    func testBluetoothStateUpdates() {
        mockCentralManager.mockState = .poweredOff
        bluetoothManager.centralManagerDidUpdateState(mockCentralManager)
        XCTAssertFalse(bluetoothManager.isBluetoothEnabled, "Bluetooth should be disabled when powered off")
        
        mockCentralManager.mockState = .poweredOn
        bluetoothManager.centralManagerDidUpdateState(mockCentralManager)
        XCTAssertTrue(bluetoothManager.isBluetoothEnabled, "Bluetooth should be enabled when powered on")
    }

    // Test Start Scanning
    func testStartScanningFindsDevices() {
        bluetoothManager.startScanning()
        XCTAssertTrue(bluetoothManager.isScanning, "Bluetooth should be scanning for devices")
        XCTAssertEqual(bluetoothManager.discoveredRadars.count, 1, "One device should be discovered")
    }

    // Test Stop Scanning
    func testStopScanningStopsDiscovery() {
        bluetoothManager.startScanning()
        bluetoothManager.stopScanning()
        XCTAssertFalse(bluetoothManager.isScanning, "Bluetooth scanning should stop")
    }

    // Test Connection Success
    func testConnectToRadar() {
        let mockDevice = RadarDevice(deviceName: "Mock Radar", batteryLevel: 100, firmwareVersion: "1.0", signalStrength: "Strong", peripheral: MockPeripheralWrapper())
        bluetoothManager.discoveredRadars.append(mockDevice) // Manually add a device

        guard let device = bluetoothManager.discoveredRadars.first else {
            XCTFail("No radar device found")
            return
        }
        
        bluetoothManager.connect(to: device)
        
        XCTAssertTrue(bluetoothManager.isConnected, "Device should be connected")
    }

    // Test Disconnection
    func testDisconnectFromRadar() {
        bluetoothManager.startScanning()
        let device = bluetoothManager.discoveredRadars.first!
        
        bluetoothManager.connect(to: device)
        bluetoothManager.disconnect()
        
        XCTAssertFalse(bluetoothManager.isConnected, "Device should be disconnected")
    }

    // Test Threat Data Parsing
    func testParseRadarData() {
        let rawData = Data([0x01, 0xA2, 0x14, 0x32]) // Example data payload
        let threats = parseRadarData(rawData)
        
        XCTAssertNotNil(threats, "Parsing should return a valid threat list")
        XCTAssertEqual(threats?.count, 1, "Should detect one threat")
        XCTAssertEqual(threats?.first?.distance, 0x14, "Threat distance should be parsed correctly")
    }
}

