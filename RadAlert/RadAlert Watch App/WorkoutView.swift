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

    @State private var isPressing = false
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
                    Text(elapsedFormatted)
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

            Text(radarStatusText)
                .font(.subheadline)
                .foregroundColor(radarStatusColor)

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

            VStack(spacing: 4) {
                Button(action: {}) {
                    Text("Stop")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isPressing ? Color.red.opacity(0.7) : Color.red)
                        .cornerRadius(10)
                }
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 1.0)
                        .onChanged { _ in isPressing = true }
                        .onEnded { _ in
                            isPressing = false
                            bluetoothManager.alertsEnabled = false
                            showingConfirmation = true
                        }
                )

                Text("Long press to stop")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
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
            bluetoothManager.onNewThreatDetected = {
                showingThreatAlert = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showingThreatAlert = false
                    }
                }
            }
            bluetoothManager.onRadarDisconnected = {
                showingDisconnectWarning = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showingDisconnectWarning = false
                    }
                }
            }
            workoutManager.onSessionExpired = {
                showingConfirmation = false
                bluetoothManager.alertsEnabled = true
                elapsedTimer?.invalidate()
                bluetoothManager.disconnect()
                appState.isRadarConnected = false
                appState.mode = .idle
            }
        }
        .onDisappear {
            bluetoothManager.alertsEnabled = true
            elapsedTimer?.invalidate()
            elapsedTimer = nil
            bluetoothManager.onNewThreatDetected = nil
            bluetoothManager.onRadarDisconnected = nil
            workoutManager.onSessionExpired = nil
        }
        .onChange(of: bluetoothManager.isConnected) { connected in
            appState.isRadarConnected = connected
        }
    }

    // MARK: - Radar Status

    private var radarStatusText: String {
        if bluetoothManager.isConnected { return "Radar Connected" }
        if bluetoothManager.isConnecting { return "Connecting..." }
        if bluetoothManager.isScanning { return "Scanning..." }
        if showingDisconnectWarning { return "Radar Lost" }
        return "No Radar"
    }

    private var radarStatusColor: Color {
        if bluetoothManager.isConnected { return .green }
        if showingDisconnectWarning { return .orange }
        return .secondary
    }

    // MARK: - Elapsed Time

    private var elapsedFormatted: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
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
