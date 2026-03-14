// SPDX-License-Identifier: MIT
//
//  BluetoothManager.swift
//  RadAlert Watch App
//

import Foundation
import CoreBluetooth

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

    // MARK: - Dependencies (injectable for testing)
    let hapticProvider: HapticProviding
    let radarStore: RadarStoreProviding

    // MARK: - Internal state (internal not private so tests can inspect/set)
    var lastThreatIDs: Set<UInt8> = []
    var lastThreatHapticAt: Date?
    var intentionalDisconnect = false

    // MARK: - Private Properties
    private let scanTimeoutInterval: TimeInterval
    private let threatHapticCooldown: TimeInterval = 1.0
    private var scanTimeoutTimer: Timer?
    private var isInitialized = false

    // Always present so CB delegate methods compile unconditionally
    private var centralManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var discoveredPeripherals: [UUID: CBPeripheral] = [:]

#if targetEnvironment(simulator)
    private var simulationTimer: Timer?
    static let simDevice1ID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    static let simDevice2ID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
#endif

    init(hapticProvider: HapticProviding = DeviceHapticProvider(),
         radarStore: RadarStoreProviding = UserDefaultsRadarStore(),
         scanTimeoutInterval: TimeInterval = 15.0) {
        self.hapticProvider = hapticProvider
        self.radarStore = radarStore
        self.scanTimeoutInterval = scanTimeoutInterval
        super.init()
        savedRadar = radarStore.load()
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

            self.discoveredDevices = (isSaved2 && !isSaved1) ? [device2, device1] : [device1, device2]

            if isSaved1 || isSaved2 {
                self.stopScanning()
                self.isConnecting = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isConnecting = false
                    self.isConnected = true
                    print("[Simulator] Saved radar found — auto-connected.")
                    self.startSimulatingThreats()
                }
            } else {
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
        scanTimedOut = false
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
        radarStore.save(radar)
        savedRadar = radar
    }

    func saveAndConnect(_ device: DiscoveredRadar) {
        saveRadar(device)
        connect(to: device)
    }

    func forgetSavedRadar() {
        radarStore.delete()
        savedRadar = nil
    }

    func disconnect() {
        scanTimeoutTimer?.invalidate()
        scanTimeoutTimer = nil
#if targetEnvironment(simulator)
        simulationTimer?.invalidate()
        simulationTimer = nil
        isScanning = false
        isConnected = false
        print("[Simulator] Radar disconnected.")
#else
        intentionalDisconnect = true
        if isScanning {
            centralManager?.stopScan()
            isScanning = false
        }
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

    // MARK: - Internal connection event handlers (also called from CB delegates)

    /// Called when a peripheral connects successfully.
    func handleConnectionSucceeded(peripheralIdentifier: UUID, peripheralName: String?) {
        isConnecting = false
        isConnected = true
        if var saved = savedRadar, saved.peripheralIdentifier == peripheralIdentifier {
            saved.lastConnectedAt = Date()
            radarStore.save(saved)
            savedRadar = saved
        }
        print("Connected to: \(peripheralName ?? "Unknown")")
    }

    /// Called when a connection attempt fails.
    func handleConnectionFailed() {
        intentionalDisconnect = false
        isConnecting = false
        connectedPeripheral = nil
    }

    /// Called on an unexpected (non-intentional) disconnect.
    func handleUnexpectedDisconnect() {
        playDisconnectHaptic()
        onRadarDisconnected?()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.startScanning()
        }
    }

    // MARK: - Private: Haptics

    private func playThreatHaptic() {
        let now = Date()
        if let lastThreatHapticAt, now.timeIntervalSince(lastThreatHapticAt) < threatHapticCooldown {
            print("Threat haptic suppressed due to cooldown.")
            return
        }
        lastThreatHapticAt = now
        for i in 0..<4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + (0.3 * Double(i))) {
                self.hapticProvider.play(.retry)
            }
        }
    }

    private func playDisconnectHaptic() {
        hapticProvider.play(.failure)
    }
}

// MARK: - CBCentralManagerDelegate
// Extension is always compiled; individual CB calls are guarded internally.

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
#if !targetEnvironment(simulator)
        DispatchQueue.main.async { self.bluetoothState = central.state }
        switch central.state {
        case .poweredOn: print("Bluetooth powered on.")
        case .poweredOff: print("Bluetooth powered off.")
        case .unauthorized: print("Bluetooth unauthorized.")
        default: print("Bluetooth state: \(central.state.rawValue)")
        }
#endif
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
#if !targetEnvironment(simulator)
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

        if isSaved {
            discoveredDevices.insert(device, at: 0)
        } else {
            discoveredDevices.append(device)
        }

        print("Discovered: \(peripheral.name ?? "Unknown") (\(suffix))")

        if isSaved {
            stopScanning()
            isConnecting = true
            connectedPeripheral = peripheral
            centralManager?.connect(peripheral, options: nil)
        }
#endif
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.handleConnectionSucceeded(peripheralIdentifier: peripheral.identifier,
                                           peripheralName: peripheral.name)
        }
#if !targetEnvironment(simulator)
        peripheral.delegate = self
        peripheral.discoverServices([BluetoothManager.garminServiceUUID])
#endif
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        print("Failed to connect: \(error?.localizedDescription ?? "unknown error")")
        handleConnectionFailed()
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        print("Disconnected from: \(peripheral.name ?? "Unknown")")
        connectedPeripheral = nil
        let wasIntentional = intentionalDisconnect
        intentionalDisconnect = false
        DispatchQueue.main.async { self.isConnected = false }
        if wasIntentional {
            print("Intentional disconnect — no retry.")
        } else {
            print("Unexpected disconnect — alerting and retrying.")
            handleUnexpectedDisconnect()
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
#if !targetEnvironment(simulator)
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == BluetoothManager.garminServiceUUID {
            peripheral.discoverCharacteristics(nil, for: service)
        }
#endif
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
#if !targetEnvironment(simulator)
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
#endif
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
#if !targetEnvironment(simulator)
        if let error = error {
            print("Error reading characteristic: \(error.localizedDescription)")
            return
        }
        guard let data = characteristic.value else { return }
        if let threats = parseRadarData(data) {
            handleThreats(threats)
        }
#endif
    }
}

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
struct Threat: Equatable {
    let id: UInt8
    let distance: UInt8
    let speed: UInt8
}

/// Parses a complete radar data payload into an array of Threats.
func parseRadarData(_ data: Data) -> [Threat]? {
    if data.count == 1 {
        print("Single-byte packet - no threats.")
        return []
    }
    guard data.count >= 4, (data.count - 1) % 3 == 0 else {
        print("Invalid payload length: \(data.count) bytes")
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

    print("Packet \(String(format: "%X", packetID)): \(threats.count) threat(s)")
    return threats
}
