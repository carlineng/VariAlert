// SPDX-License-Identifier: MIT
//
//  BluetoothManager.swift
//  VariAlertWatch Watch App
//

import Foundation
import CoreBluetooth
import WatchKit

class BluetoothManager: NSObject, ObservableObject {
    static let garminServiceUUID = CBUUID(string: "6A4E3200-667B-11E3-949A-0800200C9A66")

    var onNewThreatDetected: (() -> Void)?
    var onRadarDisconnected: (() -> Void)?

    // MARK: - Published Properties
    @Published var isScanning: Bool = false
    @Published var isConnected: Bool = false

    // MARK: - Private Properties
    private var lastThreatIDs: Set<UInt8> = []
    private var scanTimeoutTimer: Timer?
    private let scanTimeoutInterval: TimeInterval = 15.0

#if targetEnvironment(simulator)
    private var simulationTimer: Timer?
#else
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var intentionalDisconnect = false
#endif

    override init() {
        super.init()
#if !targetEnvironment(simulator)
        centralManager = CBCentralManager(delegate: self, queue: nil)
#endif
    }

    // MARK: - Public Methods

    func startScanning() {
        lastThreatIDs = []
        isScanning = true
        scanTimeoutTimer?.invalidate()
        scanTimeoutTimer = Timer.scheduledTimer(withTimeInterval: scanTimeoutInterval, repeats: false) { [weak self] _ in
            guard let self, self.isScanning else { return }
            print("Scan timed out — no radar found.")
            self.stopScanning()
        }
#if targetEnvironment(simulator)
        print("[Simulator] Simulating radar scan...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self, self.isScanning else { return }
            self.stopScanning()
            self.isConnected = true
            print("[Simulator] Radar connected.")
            self.startSimulatingThreats()
        }
#else
        guard centralManager.state == .poweredOn else {
            print("Bluetooth not powered on.")
            stopScanning()
            return
        }
        centralManager.scanForPeripherals(withServices: [BluetoothManager.garminServiceUUID], options: nil)
        print("Scanning for Garmin Varia radar...")
#endif
    }

    func stopScanning() {
        isScanning = false
        scanTimeoutTimer?.invalidate()
        scanTimeoutTimer = nil
#if !targetEnvironment(simulator)
        centralManager.stopScan()
#endif
        print("Stopped scanning.")
    }

    func disconnect() {
        scanTimeoutTimer?.invalidate()
        scanTimeoutTimer = nil
#if targetEnvironment(simulator)
        simulationTimer?.invalidate()
        simulationTimer = nil
        isConnected = false
        print("[Simulator] Radar disconnected.")
#else
        intentionalDisconnect = true
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
            connectedPeripheral = nil
            isConnected = false
        }
#endif
    }

#if targetEnvironment(simulator)
    private func startSimulatingThreats() {
        var threatID: UInt8 = 1
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            guard let self, self.isConnected else { return }
            self.handleThreats([Threat(id: threatID, distance: 50, speed: 30)])
            threatID = threatID == 255 ? 1 : threatID + 1
        }
        // Simulate an unexpected disconnect after 20s to exercise the recovery flow
        DispatchQueue.main.asyncAfter(deadline: .now() + 20.0) { [weak self] in
            guard let self, self.isConnected else { return }
            print("[Simulator] Simulating unexpected radar disconnect.")
            self.simulationTimer?.invalidate()
            self.simulationTimer = nil
            self.isConnected = false
            self.playDisconnectHaptic()
            self.onRadarDisconnected?()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.startScanning()
            }
        }
    }
#endif

    // MARK: - Private: Haptics

    private func playThreatHaptic() {
        for i in 0..<4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + (0.3 * Double(i))) {
                WKInterfaceDevice.current().play(.retry)
            }
        }
    }

    private func playDisconnectHaptic() {
        WKInterfaceDevice.current().play(.failure)
    }
}

// MARK: - CBCentralManagerDelegate

#if !targetEnvironment(simulator)
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth powered on.")
        case .poweredOff:
            print("Bluetooth powered off.")
        default:
            print("Bluetooth state: \(central.state.rawValue)")
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        print("Discovered: \(peripheral.name ?? "Unknown")")
        stopScanning()
        connectedPeripheral = peripheral
        centralManager.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        print("Connected to: \(peripheral.name ?? "Unknown")")
        peripheral.delegate = self
        peripheral.discoverServices([BluetoothManager.garminServiceUUID])
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        print("Failed to connect: \(error?.localizedDescription ?? "unknown error")")
        connectedPeripheral = nil
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        print("Disconnected from: \(peripheral.name ?? "Unknown")")
        connectedPeripheral = nil
        isConnected = false
        guard !intentionalDisconnect else {
            intentionalDisconnect = false
            return
        }
        intentionalDisconnect = false
        print("Unexpected disconnect — alerting and retrying.")
        playDisconnectHaptic()
        onRadarDisconnected?()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.startScanning()
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == BluetoothManager.garminServiceUUID {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            } else if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let error = error {
            print("Error reading characteristic: \(error.localizedDescription)")
            return
        }
        guard let data = characteristic.value else { return }

        if let threats = parseRadarData(data) {
            handleThreats(threats)
        }
    }
}
#endif

// MARK: - Threat Handling

extension BluetoothManager {
    func handleThreats(_ threats: [Threat]) {
        let currentIDs = Set(threats.map { $0.id })
        let newIDs = currentIDs.subtracting(lastThreatIDs)

        if !newIDs.isEmpty {
            print("New threat(s) detected: \(newIDs). Playing haptic alert.")
            playThreatHaptic()
            onNewThreatDetected?()
        }

        lastThreatIDs = currentIDs
    }
}

// MARK: - Radar Data Parsing

/// Represents a detected vehicle threat from the Garmin Varia radar.
struct Threat {
    let id: UInt8
    let distance: UInt8
    let speed: UInt8
}

/// Parses a complete radar data payload into an array of Threats.
func parseRadarData(_ data: Data) -> [Threat]? {
    if data.count == 1 {
        print("🔹 Single-byte packet — no threats.")
        return []
    }
    guard data.count >= 4, (data.count - 1) % 3 == 0 else {
        print("⚠️ Invalid payload length: \(data.count) bytes")
        return nil
    }

    let header = data[0]
    let packetID = header >> 4
    let threatCount = (data.count - 1) / 3
    var threats: [Threat] = []

    for i in 0..<threatCount {
        let base = 1 + i * 3
        guard base + 2 < data.count else { continue }
        threats.append(Threat(id: data[base], distance: data[base + 1], speed: data[base + 2]))
    }

    print("📡 Packet \(String(format: "%X", packetID)): \(threats.count) threat(s)")
    return threats
}
