// SPDX-License-Identifier: MIT
//
//  MockBluetooth.swift
//  VariAlert
//
//  Created by Carlin Eng on 2/6/25.
//

import CoreBluetooth

class MockCentralManager: CBCentralManager {
    var mockState: CBManagerState = .poweredOn
    
    override var state: CBManagerState {
        return mockState
    }
    
    var scannedPeripherals: [PeripheralProtocol] = []
    var connectedPeripheral: PeripheralProtocol?
    var testPeripheral: CBPeripheral? // Injected in tests

    override func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]? = nil) {
        guard let peripheral = testPeripheral else {
            print("No test peripheral available.")
            return
        }
        
        scannedPeripherals.append(MockPeripheral(name: peripheral.name ?? "Mock Radar", identifier: peripheral.identifier))
        delegate?.centralManager?(self, didDiscover: peripheral, advertisementData: [:], rssi: NSNumber(value: -50))
    }
    
    override func stopScan() {
        scannedPeripherals.removeAll()
    }
    
    override func connect(_ peripheral: CBPeripheral, options: [String : Any]? = nil) {
        connectedPeripheral = MockPeripheral(name: peripheral.name ?? "Mock Radar", identifier: peripheral.identifier)
        delegate?.centralManager?(self, didConnect: peripheral)
    }
    
    override func cancelPeripheralConnection(_ peripheral: CBPeripheral) {
        connectedPeripheral = nil
        delegate?.centralManager?(self, didDisconnectPeripheral: peripheral, error: nil)
    }
}

// Define a protocol for mockable peripherals
protocol PeripheralProtocol {
    var name: String? { get }
    var identifier: UUID { get }
}

// Use a struct to mock peripheral behavior
struct MockPeripheral: PeripheralProtocol {
    var name: String?
    var identifier: UUID
}


