// SPDX-License-Identifier: MIT
//
//  BluetoothManager.swift
//  RadAlert Watch App
//

import Foundation
import CoreBluetooth
import WatchKit

class BluetoothManager: NSObject, ObservableObject {
    static let garminServiceUUID = CBUUID(string: "6A4E3200-667B-11E3-949A-0800200C9A66")

    var onNewThreatDetected: (() -> Void)?
    var onRadarDisconnected: (() -> Void)?
    var alertsEnabled: Bool = true

    // MARK: - Published Properties
    @Published var isScanning: Bool = false
    @Published var isConnecting: Bool = false
    @Published var isConnected: Bool = false
    @Published var scanTimedOut: Bool = false
    @Published var vehicleCount: Int = 0
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var discoveredDevices: [DiscoveredRadar] = []
    @Published var savedRadar: SavedRadar?

    var isAuthorized: Bool {
        bluetoothState != .unauthorized && bluetoothState != .unsupported
    }

    // MARK: - Private Properties
    private var lastThreatIDs: Set<UInt8> = []
    private var scanTimeoutTimer: Timer?
    private let scanTimeoutInterval: TimeInterval = 15.0
    private var isInitialized = false

#if targetEnvironment(simulator)
    private var simulationTimer: Timer?
    static let simDevice1ID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    static let simDevice2ID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
#else
    private var centralManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var discoveredPeripherals: [UUID: CBPeripheral] = [:]
    private var intentionalDisconnect = false
#endif

    override init() {
        super.init()
        savedRadar = SavedRadar.load()
    }

    func initialize() {
        guard !isInitialized else { return }
        isInitialized = true
#if targetEnvironment(simulator)
        bluetoothState = .poweredOn
#else
        centralManager = CBCentralManager(delegate: self, queue: nil)
#endif
    }

    // MARK: - Public Methods

    func startScanning() {
        lastThreatIDs = []
        discoveredDevices = []
        isScanning = true
        scanTimedOut = false
        scanTimeoutTimer?.invalidate()
        scanTimeoutTimer = Timer.scheduledTimer(withTimeInterval: scanTimeoutInterval, repeats: false) { [weak self] _ in
            guard let self, self.isScanning else { return }
            print("Scan timed out — no saved radar found.")
            self.scanTimedOut = true
            self.stopScanning()
        }
#if targetEnvironment(simulator)
        print("[Simulator] Simulating radar scan...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self, self.isScanning else { return }

            let saved = self.savedRadar
            let isSaved1 = saved?.peripheralIdentifier == Self.simDevice1ID
            let isSaved2 = saved?.peripheralIdentifier == Self.simDevice2ID

            let device1 = DiscoveredRadar(id: Self.simDevice1ID, name: "Varia RTL515",
                                          rssi: -55, identifierSuffix: "A4B2", isSaved: isSaved1)
            let device2 = DiscoveredRadar(id: Self.simDevice2ID, name: "Varia RTL516",
                                          rssi: -72, identifierSuffix: "C7D9", isSaved: isSaved2)

            // Saved radar sorts to top
            self.discoveredDevices = (isSaved2 && !isSaved1) ? [device2, device1] : [device1, device2]

            // Auto-connect if this is the saved radar
            if isSaved1 || isSaved2 {
                self.stopScanning()
                self.isConnected = true
                print("[Simulator] Saved radar found — auto-connected.")
                self.startSimulatingThreats()
            } else {
                // No saved radar → stop scanning so UI can show selection
                self.scanTimedOut = true
                self.stopScanning()
                print("[Simulator] No saved radar — showing selection.")
            }
        }
#else
        guard let centralManager, centralManager.state == .poweredOn else {
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
        centralManager?.stopScan()
#endif
        print("Stopped scanning.")
    }

    func connect(to device: DiscoveredRadar) {
        isConnecting = true
#if targetEnvironment(simulator)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isConnecting = false
            self.isConnected = true
            print("[Simulator] Connected to \(device.name).")
            self.startSimulatingThreats()
        }
#else
        guard let peripheral = discoveredPeripherals[device.id] else {
            print("Peripheral not found for \(device.name).")
            isConnecting = false
            return
        }
        stopScanning()
        connectedPeripheral = peripheral
        centralManager?.connect(peripheral, options: nil)
#endif
    }

    func saveRadar(_ device: DiscoveredRadar) {
        let radar = SavedRadar(
            peripheralIdentifier: device.id,
            displayName: device.name,
            identifierSuffix: device.identifierSuffix,
            lastConnectedAt: nil
        )
        radar.save()
        savedRadar = radar
    }

    func saveAndConnect(_ device: DiscoveredRadar) {
        saveRadar(device)
        connect(to: device)
    }

    func forgetSavedRadar() {
        SavedRadar.delete()
        savedRadar = nil
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
            centralManager?.cancelPeripheralConnection(peripheral)
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
        DispatchQueue.main.async {
            self.bluetoothState = central.state
        }
        switch central.state {
        case .poweredOn:
            print("Bluetooth powered on.")
        case .poweredOff:
            print("Bluetooth powered off.")
        case .unauthorized:
            print("Bluetooth unauthorized.")
        default:
            print("Bluetooth state: \(central.state.rawValue)")
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        let uuid = peripheral.identifier
        guard !discoveredDevices.contains(where: { $0.id == uuid }) else { return }

        let suffix = String(uuid.uuidString.suffix(4))
        let isSaved = savedRadar?.peripheralIdentifier == uuid
        let device = DiscoveredRadar(
            id: uuid,
            name: peripheral.name ?? "Varia Radar",
            rssi: RSSI.intValue,
            identifierSuffix: suffix,
            isSaved: isSaved
        )
        discoveredPeripherals[uuid] = peripheral

        // Already on main queue (CBCentralManager initialized with queue: nil)
        if isSaved {
            discoveredDevices.insert(device, at: 0)
        } else {
            discoveredDevices.append(device)
        }

        print("Discovered: \(peripheral.name ?? "Unknown") (\(suffix))")

        // Auto-connect only to the saved radar; wait for others
        if isSaved {
            stopScanning()
            connectedPeripheral = peripheral
            centralManager?.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.isConnecting = false
            self.isConnected = true
            // Update lastConnectedAt for the saved radar
            if var saved = self.savedRadar, saved.peripheralIdentifier == peripheral.identifier {
                saved.lastConnectedAt = Date()
                saved.save()
                self.savedRadar = saved
            }
        }
        print("Connected to: \(peripheral.name ?? "Unknown")")
        peripheral.delegate = self
        peripheral.discoverServices([BluetoothManager.garminServiceUUID])
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        print("Failed to connect: \(error?.localizedDescription ?? "unknown error")")
        isConnecting = false
        connectedPeripheral = nil
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        print("Disconnected from: \(peripheral.name ?? "Unknown")")
        connectedPeripheral = nil
        DispatchQueue.main.async { self.isConnected = false }
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
            vehicleCount += newIDs.count
            if alertsEnabled {
                print("New threat(s) detected: \(newIDs). Playing haptic alert.")
                playThreatHaptic()
                onNewThreatDetected?()
            }
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
