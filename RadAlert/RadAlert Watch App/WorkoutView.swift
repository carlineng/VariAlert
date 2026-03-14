// SPDX-License-Identifier: MIT
//
//  WorkoutView.swift
//  RadAlert Watch App
//

import SwiftUI

struct WorkoutView: View {
    @EnvironmentObject var appState: WatchAppState
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var workoutManager: WorkoutSessionManager

    @StateObject private var coordinator = WorkoutCoordinator()
    @State private var elapsedSeconds: Int = 0
    @State private var elapsedTimer: Timer?
    @State private var showingThreatAlert = false
    @State private var showingDisconnectWarning = false
    @State private var showingConfirmation = false
    @State private var showingRadarSelection = false

    var body: some View {
        VStack(spacing: 12) {
            // Metrics row
            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text(formatElapsed(elapsedSeconds))
                        .font(.title2.monospacedDigit())
                    Text("Elapsed")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 2) {
                    Text("\(bluetoothManager.vehicleCount)")
                        .font(.title2.monospacedDigit())
                    Text("Vehicles")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            HStack(spacing: 5) {
                Circle()
                    .fill(pillState.dotColor)
                    .frame(width: 7, height: 7)
                Text(pillState.text)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(pillState.dotColor.opacity(0.15))
            .cornerRadius(20)

            if bluetoothManager.scanTimedOut && !bluetoothManager.isConnected && !bluetoothManager.isConnecting {
                if bluetoothManager.savedRadar != nil {
                    Button("Keep Searching") {
                        bluetoothManager.startScanning()
                    }
                    .foregroundColor(.orange)

                    Button("New Radar") {
                        bluetoothManager.discoveredDevices = []
                        bluetoothManager.startScanning()
                        showingRadarSelection = true
                    }
                    .foregroundColor(.blue)

                    Button("Cancel Ride") {
                        bluetoothManager.disconnect()
                        workoutManager.endAndDiscard {
                            appState.isRadarConnected = false
                            appState.mode = .idle
                        }
                    }
                    .foregroundColor(.red)
                } else {
                    Button("Scan Again") {
                        bluetoothManager.startScanning()
                    }
                    .foregroundColor(.orange)
                }
            }

            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(white: 0.2))
                RoundedRectangle(cornerRadius: 10)
                    .trim(from: 0, to: coordinator.holdProgress)
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                Text("Stop")
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .contentShape(RoundedRectangle(cornerRadius: 10))
            .onLongPressGesture(minimumDuration: 1.0, pressing: { pressing in
                if pressing {
                    coordinator.startHold()
                } else {
                    withAnimation(.easeOut(duration: 0.2)) {
                        coordinator.cancelHold()
                    }
                }
            }, perform: {
                coordinator.completeHold(bluetoothManager: bluetoothManager)
                showingConfirmation = true
            })
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.red, lineWidth: 6)
                .opacity(showingThreatAlert ? 1 : 0)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.orange, lineWidth: 6)
                .opacity(showingDisconnectWarning ? 1 : 0)
        )
        .sheet(isPresented: $showingConfirmation, onDismiss: {
            bluetoothManager.alertsEnabled = true
        }) {
            EndRideSheet(
                onResume: {
                    bluetoothManager.alertsEnabled = true
                    showingConfirmation = false
                },
                onSave: {
                    bluetoothManager.disconnect()
                    workoutManager.endAndSave {
                        appState.isRadarConnected = false
                        appState.mode = .idle
                    }
                },
                onDiscard: {
                    bluetoothManager.disconnect()
                    workoutManager.endAndDiscard {
                        appState.isRadarConnected = false
                        appState.mode = .idle
                    }
                }
            )
        }
        .sheet(isPresented: $showingRadarSelection) {
            RadarSelectionView(
                onConnect: { device in
                    bluetoothManager.saveAndConnect(device)
                    showingRadarSelection = false
                },
                onCancel: {
                    bluetoothManager.stopScanning()
                    showingRadarSelection = false
                }
            )
        }
        .onAppear {
            startElapsedTimer()
            bluetoothManager.vehicleCount = 0
            bluetoothManager.startScanning()
            coordinator.register(
                bluetoothManager: bluetoothManager,
                workoutManager: workoutManager,
                onThreatDetected: {
                    showingThreatAlert = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeOut(duration: 0.5)) { showingThreatAlert = false }
                    }
                },
                onDisconnected: {
                    showingDisconnectWarning = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation(.easeOut(duration: 0.5)) { showingDisconnectWarning = false }
                    }
                },
                onSessionExpired: {
                    showingConfirmation = false
                    bluetoothManager.alertsEnabled = true
                    elapsedTimer?.invalidate()
                    bluetoothManager.disconnect()
                    appState.isRadarConnected = false
                    appState.mode = .idle
                }
            )
        }
        .onDisappear {
            bluetoothManager.alertsEnabled = true
            elapsedTimer?.invalidate()
            elapsedTimer = nil
            coordinator.teardown(bluetoothManager: bluetoothManager, workoutManager: workoutManager)
        }
        .onChange(of: bluetoothManager.isConnected) {
            appState.isRadarConnected = bluetoothManager.isConnected
        }
    }

    // MARK: - Radar Status

    private var pillState: RadarPillState {
        RadarPillState(
            isConnected: bluetoothManager.isConnected,
            isConnecting: bluetoothManager.isConnecting,
            isScanning: bluetoothManager.isScanning,
            isDisconnectWarning: showingDisconnectWarning
        )
    }

    private func startElapsedTimer() {
        if let workoutStartDate = workoutManager.workoutStartDate {
            elapsedSeconds = max(0, Int(Date().timeIntervalSince(workoutStartDate)))
        } else {
            elapsedSeconds = 0
        }
        elapsedTimer?.invalidate()
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let workoutStartDate = workoutManager.workoutStartDate {
                elapsedSeconds = max(0, Int(Date().timeIntervalSince(workoutStartDate)))
            } else {
                elapsedSeconds += 1
            }
        }
    }
}

// MARK: - End Ride Confirmation Sheet

private struct EndRideSheet: View {
    let onResume: () -> Void
    let onSave: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onResume) {
                Text("Resume")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)

            Button(action: onSave) {
                Text("End and Save")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button(role: .destructive, action: onDiscard) {
                Text("End and Discard")
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
    }
}

// MARK: - WorkoutCoordinator

/// Owns the hold-to-stop mechanic and workout callback lifecycle.
/// Extracted as an ObservableObject so it can be tested independently of SwiftUI.
class WorkoutCoordinator: ObservableObject {
    @Published private(set) var holdProgress: CGFloat = 0
    private var holdTimer: Timer?
    var onHoldComplete: (() -> Void)?

    func startHold() {
        holdTimer?.invalidate()
        holdTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self else { return }
            holdProgress = min(holdProgress + 0.05, 1.0)
        }
    }

    func cancelHold() {
        holdTimer?.invalidate()
        holdTimer = nil
        holdProgress = 0
    }

    func completeHold(bluetoothManager: BluetoothManager) {
        holdTimer?.invalidate()
        holdTimer = nil
        holdProgress = 0
        bluetoothManager.alertsEnabled = false
        onHoldComplete?()
    }

    func register(bluetoothManager: BluetoothManager,
                  workoutManager: WorkoutSessionManager,
                  onThreatDetected: @escaping () -> Void,
                  onDisconnected: @escaping () -> Void,
                  onSessionExpired: @escaping () -> Void) {
        bluetoothManager.onNewThreatDetected = onThreatDetected
        bluetoothManager.onRadarDisconnected = onDisconnected
        workoutManager.onSessionExpired = onSessionExpired
    }

    func teardown(bluetoothManager: BluetoothManager, workoutManager: WorkoutSessionManager) {
        cancelHold()
        bluetoothManager.onNewThreatDetected = nil
        bluetoothManager.onRadarDisconnected = nil
        workoutManager.onSessionExpired = nil
    }
}

// MARK: - Testable helpers

/// Formats elapsed seconds as M:SS or H:MM:SS.
func formatElapsed(_ seconds: Int) -> String {
    let h = seconds / 3600
    let m = (seconds % 3600) / 60
    let s = seconds % 60
    return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
}

/// Encapsulates radar connection state for the status pill.
struct RadarPillState {
    let isConnected: Bool
    let isConnecting: Bool
    let isScanning: Bool
    let isDisconnectWarning: Bool

    var text: String {
        if isConnected { return "Connected" }
        if isConnecting { return "Connecting" }
        if isScanning { return "Searching" }
        if isDisconnectWarning { return "Lost" }
        return "No Radar"
    }

    var dotColor: Color {
        if isConnected { return .green }
        if isConnecting || isScanning { return .yellow }
        if isDisconnectWarning { return .red }
        return .gray
    }
}
