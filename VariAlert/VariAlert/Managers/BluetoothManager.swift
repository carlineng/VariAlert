// SPDX-License-Identifier: MIT
//
//  BluetoothManager.swift
//  VariAlert
//
//  Created by Carlin Eng on 2/2/25.
//

import Foundation
import CoreBluetooth
import Combine

class BluetoothManager: NSObject, ObservableObject {
    static let garminServiceUUID = CBUUID(string: "6A4E3200-667B-11E3-949A-0800200C9A66")
    static let deviceInfoService = "180A"
    
    var onThreatsReceived: (([Threat]) -> Void)?

    // MARK: - Published Properties
    @Published var discoveredRadars: [RadarDevice] = []
    @Published var discoveredCharacteristics: [CBCharacteristic] = []
    @Published var isScanning: Bool = false
    @Published var isBluetoothEnabled: Bool = true
    @Published var isConnected: Bool = false

    // MARK: - Private Properties
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?

    // Keep references to discovered peripherals, etc.
    weak var appState: AppStateViewModel?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // initializer for injecting mock instances
    init(centralManager: CBCentralManager) {
        self.centralManager = centralManager
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Begin scanning for Garmin Varia radar devices.
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            print("Bluetooth is not powered on.")
            isBluetoothEnabled = false
            isScanning = false
            self.stopScanning()
            return
        }
        
        isBluetoothEnabled = true
        isScanning = true
        discoveredRadars.removeAll()
        
        centralManager.scanForPeripherals(withServices: [BluetoothManager.garminServiceUUID], options: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { // Stop after 5 seconds
            self.stopScanning()
        }
    }
    
    /// Stop scanning for devices.
    func stopScanning() {
        isScanning = false
        centralManager?.stopScan()
        print("Stopped scanning.")
    }
    
    /// Attempt to connect to a specific radar device.
    func connect(to device: RadarDevice) {
        // Normally you'd have a reference to the matching CBPeripheral
        // Then you call centralManager?.connect(peripheral, options: nil)
        print("Attempting to connect to \(device.deviceName).")
        // Connect to the specific CBPeripheral that corresponds to the device
        guard discoveredRadars.contains(where: { $0.deviceName == device.deviceName }) else { return }
        centralManager.connect(device.peripheral, options: nil)
        self.stopScanning()
    }
    
    /// Disconnect from currently connected device (if any).
    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
            connectedPeripheral = nil
            isConnected = false
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate, CBPeripheralDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown, .resetting, .unsupported, .unauthorized:
            print("Bluetooth state not valid for scanning.")
        case .poweredOff:
            print("Bluetooth powered off.")
        case .poweredOn:
            print("Bluetooth powered on. Ready to scan.")
        @unknown default:
            print("Unknown Bluetooth state.")
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        let radarDevice = RadarDevice(
            deviceName: peripheral.name ?? "Unknown",
            batteryLevel: 0, // Placeholder, update as needed
            firmwareVersion: "Unknown", // Placeholder, update as needed
            signalStrength: "\(RSSI)",
            peripheral: peripheral
        )
        
        // Avoid adding duplicates
        if !discoveredRadars.contains(where: { $0.peripheral.identifier == peripheral.identifier }) {
            discoveredRadars.append(radarDevice)
        }
        
        print("Discovered device: \(radarDevice.deviceName)")
    }
    
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        isConnected = true
        print("Connected to: \(peripheral.name ?? "Unknown device")")
        
        peripheral.delegate = self
        peripheral.discoverServices([BluetoothManager.garminServiceUUID])
        
        if let radarDevice = discoveredRadars.first(where: { $0.deviceName == peripheral.name }) {
            DispatchQueue.main.async {
                self.appState?.didConnect(to: radarDevice)
            }
        } else {
            isConnected = false
            self.disconnect()
            print("⚠️ No matching RadarDevice found for \(peripheral.name ?? "Unknown device")")
            DispatchQueue.main.async {
                self.appState?.didDisconnect()
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        print("Failed to connect: \(error?.localizedDescription ?? "unknown error")")
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        print("Disconnected from \(peripheral.name ?? "Unknown")")
        connectedPeripheral = nil
        isConnected = false
        print("Disconnected from: \(peripheral.name ?? "Unknown device")")
        DispatchQueue.main.async {
            self.appState?.didDisconnect()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        
        if let services = peripheral.services {
            for service in services {
                if service.uuid == BluetoothManager.garminServiceUUID {
                    peripheral.discoverCharacteristics(nil, for: service)
                    break
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }

        if let characteristics = service.characteristics {
            if service.uuid == BluetoothManager.garminServiceUUID {
                discoveredCharacteristics = characteristics
                for characteristic in characteristics {
                    if characteristic.properties.contains(.notify) {
                        peripheral.setNotifyValue(true, for: characteristic)
                    } else if characteristic.properties.contains(.read) {
                        peripheral.readValue(for: characteristic)
                    } else {
                        print("Characteristic \(characteristic.uuid.uuidString) is neither readable nor notifiable")
                    }
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        if let error = error {
            print("Error updating value for characteristic: \(error.localizedDescription)")
            return
        }

        if let index = discoveredCharacteristics.firstIndex(where: { $0.uuid == characteristic.uuid }) {
            discoveredCharacteristics[index] = characteristic
        }
        
        if let data = characteristic.value {
            if let threats = parseRadarData(data) {
                // Now we have an array of Threat objects.
                // Pass data to the ViewModel or take appropriate action.
                
                onThreatsReceived?(threats)

                // Logging statement:
                for threat in threats {
                    print("Threat id: \(String(format: "%02X", threat.id)), distance: \(threat.distance)m, speed: \(threat.speed) km/h")
                }
            }
        }
    }
}

/// Parses a complete radar data payload into an array of Threats.
/// - Parameter data: A Data object representing a complete payload (1 + 3*i bytes).
/// - Returns: An array of Threat objects, or nil if the payload length is invalid.
func parseRadarData(_ data: Data) -> [Threat]? {
    var threats: [Threat] = []
    if data.count == 1 {
        print("🔹 Received single-byte packet (\(String(format: "%02X", data[0]))) - No threats detected.")
        return threats
    }

    // The payload must be at least 4 bytes (header + one threat)
    guard data.count >= 4, (data.count - 1) % 3 == 0 else {
        print("⚠️ Invalid payload length: \(data.count) bytes - ignoring")
        return nil
    }
    
    // The first byte is the header.
    // You might extract the packet identifier if needed:
    let header = data[0]
    let packetID = header >> 4   // high nibble (first 4 bits)
    // let otherInfo = header & 0x0F  // lower nibble, if needed
    
    let threatCount = (data.count - 1) / 3

    
    for i in 0..<threatCount {
        let base = 1 + i * 3
        // Ensure we have enough bytes (should always be true due to our guard above)
        guard base + 2 < data.count else { continue }
        
        let threatID = data[base]
        let distance = data[base + 1]
        let speed = data[base + 2]
        
        let threat = Threat(id: threatID, distance: distance, speed: speed)
        threats.append(threat)
    }
    
    print("📡 Parsed packet \(String(format: "%X", packetID)) with \(threats.count) threat(s)")
    return threats
}
