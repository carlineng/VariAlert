# RadAlert: Screens, States, and Flows

## Overview

RadAlert is a standalone watchOS app that delivers supplemental haptic alerts from a Garmin Varia radar during cycling workouts. It connects directly to the radar via Bluetooth, monitors for approaching vehicles, and vibrates the watch when new threats are detected. An active HealthKit workout session keeps the app alive in the background.

There is no companion iPhone app required at runtime.

---

## Screens

### OnboardingView

Shown on first launch only (`hasCompletedOnboarding == false`).

A 3-page TabView:

| Page | Title | Content |
|------|-------|---------|
| 0 | "RadAlert" | Describes the app's purpose — supplemental haptic alerts from Garmin Varia radar |
| 1 | "What You Need" | Lists requirements: Garmin Varia radar, Bluetooth, Health access |
| 2 | "Safety Notice" | Warning that this is a supplemental tool, not a certified safety device. "Get Started" button |

"Get Started" action:
- Calls `bluetoothManager.initialize()`
- Calls `workoutManager.requestAuthorization`
- Sets `hasCompletedOnboarding = true` → ContentView re-renders

---

### Permission Denial Screens

**BluetoothDeniedView** — shown when `bluetoothState == .unauthorized` or `.unsupported`. Instructs the user to enable Bluetooth in iPhone Settings.

**HealthKitDeniedView** — shown when `!workoutManager.isHealthKitAuthorized`. Instructs the user to enable Health access in the iPhone Health app.

Both are permanent states until permission is granted externally.

---

### ContentView (Root)

The root container. Renders one of the following in order:

1. If `!hasCompletedOnboarding` → **OnboardingView**
2. If `bluetoothState == .unknown` → loading spinner
3. If `!isAuthorized` → **BluetoothDeniedView**
4. If `!workoutManager.isHealthKitAuthorized` → **HealthKitDeniedView**
5. If `appState.mode == .idle` → **IdleView**
6. If `appState.mode == .workout` → **WorkoutView**

On appear (when already onboarded): calls `bluetoothManager.initialize()` to start the BT stack.

---

### IdleView

The pre-ride home screen. Shown when `appState.mode == .idle`.

**Elements:**
- "RadAlert" title
- "Start Ride" button (primary)
- "Settings" text button (secondary)

**"Start Ride" logic:**
- If `savedRadar != nil` → call `startWorkout()`, on success set `appState.mode = .workout`
- If `savedRadar == nil` → clear discovered devices, start scanning, show **RadarSelectionView** sheet

---

### RadarSelectionView

A modal sheet for picking a radar device to connect to. Triggered from:
- IdleView (no saved radar when starting a ride)
- SettingsView ("Change Radar")
- WorkoutView ("New Radar" button mid-ride)

**States:**

| Condition | UI |
|-----------|----|
| `isScanning == true` | Spinner + "Scanning..." |
| `discoveredDevices.isEmpty && !isScanning` | "No radar found" + help text |
| `discoveredDevices.count == 1` | Device name, ID suffix, enabled "Connect" button |
| `discoveredDevices.count > 1` | Selectable list; radio-button style; "Connect" enabled on selection |

**Buttons:**
- **Connect** — enabled when a device is selected or exactly one device is found
- **Rescan** — restarts scan; disabled while actively scanning
- **Cancel** — stops scan and closes the sheet

---

### WorkoutView

The active ride screen. Shown when `appState.mode == .workout`.

**Metrics row:**
- Elapsed time (updates every 1 second from `workoutStartDate`)
- Vehicle count (increments per new detected threat)

**Radar status line:**

| State | Text | Color |
|-------|------|-------|
| `isConnected` | "Radar Connected" | Green |
| `isConnecting` | "Connecting..." | Secondary |
| `isScanning` | "Scanning..." | Secondary |
| `showingDisconnectWarning` | "Radar Lost" | Orange |
| None of above | "No Radar" | Secondary |

**Timeout action buttons** (shown when `scanTimedOut && !isConnected && !isConnecting`):

If `savedRadar != nil`:
- **Keep Searching** — restarts scan
- **New Radar** — opens RadarSelectionView to pick a different device
- **Cancel Ride** — disconnects and discards the workout, returns to idle

If `savedRadar == nil`:
- **Scan Again** — restarts scan

**Stop button:**
- Red, full-width
- Requires a 1-second long press to activate (prevents accidental taps)
- On trigger: disables threat alerts, shows **EndRideSheet**

**Visual overlays:**
- **Red border** — appears for 1.5 seconds when a new vehicle threat is detected
- **Orange border** — appears for 3.0 seconds when the radar disconnects

---

### EndRideSheet

A modal sheet presented when the user long-presses the Stop button.

| Button | Action |
|--------|--------|
| **Resume** (green) | Re-enables alerts, dismisses sheet, continues the ride |
| **End and Save** | Disconnects radar, saves HealthKit workout, returns to idle |
| **End and Discard** | Disconnects radar, discards HealthKit workout, returns to idle |

Swiping the sheet away (watchOS dismiss gesture) also re-enables alerts.

---

### SettingsView

A modal sheet opened from IdleView. Manages the saved radar preference.

**Displays (if a radar is saved):**
- Radar display name (e.g., "Varia RTL515")
- Identifier: "ID: ···XXXX" (last 4 characters of Bluetooth UUID)
- Last connected date (MM/DD format)

**Buttons:**
- **Change Radar** — starts scanning, opens RadarSelectionView; on connect, overwrites saved radar and closes both sheets
- **Forget Radar** — deletes the saved radar from UserDefaults, closes Settings
- **Privacy Policy** — opens the privacy policy in Safari
- **Done** — closes Settings

---

## State Variables

### WatchAppState

| Property | Type | Description |
|----------|------|-------------|
| `mode` | `.idle` / `.workout` | Top-level app mode; drives ContentView routing |
| `isRadarConnected` | `Bool` | Mirrors `bluetoothManager.isConnected`; updated via `onChange` in WorkoutView |

### BluetoothManager (Published)

| Property | Type | Description |
|----------|------|-------------|
| `isScanning` | `Bool` | Actively scanning for peripherals |
| `isConnecting` | `Bool` | BLE connection in progress |
| `isConnected` | `Bool` | Radar peripheral connected |
| `scanTimedOut` | `Bool` | Set after 15-second scan timeout |
| `vehicleCount` | `Int` | Running total of new threats detected |
| `bluetoothState` | `CBManagerState` | Current Core Bluetooth manager state |
| `discoveredDevices` | `[DiscoveredRadar]` | Radars found during current scan |
| `savedRadar` | `SavedRadar?` | Persisted radar choice (loaded from UserDefaults) |

### BluetoothManager (Non-Published)

| Property | Type | Description |
|----------|------|-------------|
| `alertsEnabled` | `Bool` | When `false`, haptics are suppressed (during stop confirmation) |
| `lastThreatIDs` | `Set<UInt8>` | Threat IDs from the previous BLE packet; used for deduplication |
| `onNewThreatDetected` | `() -> Void?` | Callback fired when new threats appear |
| `onRadarDisconnected` | `() -> Void?` | Callback fired on unexpected disconnect |

### WorkoutSessionManager

| Property | Type | Description |
|----------|------|-------------|
| `workoutStartDate` | `Date?` | Non-nil during an active session; used for elapsed time calculation |
| `isHealthKitAuthorized` | `Bool` | Computed; checks HKHealthStore authorization status |
| `onSessionExpired` | `() -> Void?` | Callback fired if the session ends unexpectedly (e.g., OS terminates it) |

### WorkoutView (@State)

| Property | Description |
|----------|-------------|
| `isPressing` | Long-press visual state for the Stop button |
| `elapsedSeconds` | Seconds elapsed since ride start |
| `elapsedTimer` | 1-second repeating Timer |
| `showingThreatAlert` | Drives red border overlay |
| `showingDisconnectWarning` | Drives orange border overlay |
| `showingConfirmation` | Shows/hides EndRideSheet |
| `showingRadarSelection` | Shows/hides RadarSelectionView (mid-ride "New Radar") |

---

## Complete App Flows

### App Launch

```
App opens
│
├─ hasCompletedOnboarding == false
│  └─ OnboardingView (3 pages)
│     └─ "Get Started" tapped
│        ├─ bluetoothManager.initialize()
│        ├─ workoutManager.requestAuthorization()
│        └─ hasCompletedOnboarding = true
│
└─ hasCompletedOnboarding == true
   ├─ ContentView.onAppear → bluetoothManager.initialize()
   ├─ bluetoothState == .unknown → spinner (transient)
   ├─ Not authorized → permission denied screen (permanent until fixed externally)
   └─ Authorized → IdleView
```

---

### Starting a Ride (Saved Radar)

```
IdleView: "Start Ride" tapped, savedRadar != nil
│
├─ workoutManager.startWorkout()
│  └─ HKWorkoutSession begins
│
└─ appState.mode = .workout → WorkoutView appears
   │
   └─ onAppear:
      ├─ vehicleCount = 0
      ├─ bluetoothManager.startScanning()
      ├─ Register threat/disconnect/session-expired callbacks
      │
      ├─ Saved radar found within 15s:
      │  ├─ Auto-connects (no user action needed)
      │  └─ Radar status: "Radar Connected" (green)
      │
      └─ Timeout (15s, no connection):
         ├─ scanTimedOut = true
         └─ Buttons appear: "Keep Searching" / "New Radar" / "Cancel Ride"
```

---

### Starting a Ride (No Saved Radar)

```
IdleView: "Start Ride" tapped, savedRadar == nil
│
├─ discoveredDevices = []
├─ bluetoothManager.startScanning()
└─ RadarSelectionView sheet appears
   │
   ├─ Scanning: spinner shown
   ├─ Device(s) found: list or single-confirm layout
   │
   ├─ "Connect" tapped:
   │  ├─ saveRadar(device) — persists to UserDefaults
   │  ├─ stopScanning()
   │  ├─ RadarSelectionView dismissed
   │  └─ workoutManager.startWorkout()
   │     └─ appState.mode = .workout → WorkoutView appears
   │
   └─ "Cancel" tapped:
      ├─ stopScanning()
      ├─ Sheet dismissed
      └─ Back to IdleView (no ride started)
```

---

### Active Ride: Threat Detection

```
Radar sends BLE characteristic notification
│
├─ parseRadarData(data) → [Threat(id, distance, speed)]
├─ handleThreats(threats):
│  ├─ newIDs = currentIDs − lastThreatIDs
│  ├─ vehicleCount += newIDs.count
│  └─ If alertsEnabled:
│     ├─ playThreatHaptic(): 4× .retry pulses, 0.3s spacing (max 1/second)
│     └─ onNewThreatDetected():
│        ├─ showingThreatAlert = true
│        └─ Auto-clears after 1.5s (red border overlay)
│
└─ lastThreatIDs = currentIDs
```

---

### Active Ride: Radar Disconnects

```
Unexpected BLE disconnect
│
├─ playDisconnectHaptic(): 1× .failure pulse
├─ onRadarDisconnected():
│  ├─ showingDisconnectWarning = true → "Radar Lost" status + orange border
│  └─ Auto-clears after 3.0s
│
└─ Auto-reconnect: startScanning() after 2s delay
   ├─ Saved radar re-discovered → auto-connects
   └─ Timeout (15s) → timeout buttons appear
```

---

### Mid-Ride Radar Selection

```
WorkoutView: timeout buttons visible, "New Radar" tapped
│
├─ discoveredDevices = []
├─ bluetoothManager.startScanning()
└─ RadarSelectionView sheet appears
   │
   ├─ User selects device + "Connect":
   │  ├─ bluetoothManager.saveAndConnect(device)
   │  │  ├─ saveRadar(device) — overwrites persisted saved radar
   │  │  └─ connect(to: device) — begins BLE connection
   │  │     └─ scanTimedOut = false, isConnecting = true
   │  │
   │  └─ Sheet dismissed → WorkoutView shows "Connecting..."
   │
   └─ "Cancel" tapped:
      ├─ stopScanning()
      └─ Back to WorkoutView
```

---

### Ending a Ride

```
WorkoutView: Stop button held for 1 second
│
├─ alertsEnabled = false (suppress alerts during review)
└─ EndRideSheet appears
   │
   ├─ "Resume":
   │  ├─ alertsEnabled = true
   │  └─ Back to active ride
   │
   ├─ "End and Save":
   │  ├─ bluetoothManager.disconnect() [intentional — no disconnect haptic]
   │  ├─ workoutManager.endAndSave()
   │  │  ├─ Ends HKWorkoutSession
   │  │  ├─ finishWorkout() → saved to Apple Health
   │  │  └─ workoutStartDate = nil
   │  └─ appState.mode = .idle → IdleView
   │
   └─ "End and Discard":
      ├─ bluetoothManager.disconnect()
      ├─ workoutManager.endAndDiscard()
      │  ├─ Ends HKWorkoutSession
      │  ├─ discardWorkout() → not saved to Apple Health
      │  └─ workoutStartDate = nil
      └─ appState.mode = .idle → IdleView
```

---

### Session Expired (Edge Case)

```
HKWorkoutSession ends unexpectedly (e.g., OS terminates it)
│
├─ workoutManager.onSessionExpired fires
├─ showingConfirmation = false (close stop sheet if open)
├─ alertsEnabled = true (re-enable alerts)
├─ elapsedTimer?.invalidate()
├─ bluetoothManager.disconnect()
├─ appState.isRadarConnected = false
└─ appState.mode = .idle → IdleView
```

---

### Settings

```
IdleView: "Settings" tapped
│
└─ SettingsView sheet appears
   ├─ Saved radar info displayed (name, ID suffix, last connected)
   │
   ├─ "Change Radar":
   │  ├─ startScanning()
   │  └─ RadarSelectionView sheet appears
   │     ├─ User picks device → saveRadar() + stopScanning() → both sheets close
   │     └─ Cancel → stopScanning() → RadarSelectionView closes (Settings stays open)
   │
   ├─ "Forget Radar":
   │  ├─ SavedRadar.delete() from UserDefaults
   │  ├─ savedRadar = nil
   │  └─ SettingsView closes
   │
   └─ "Done" → SettingsView closes
```

---

## Data Persistence

| Key | Type | Content |
|-----|------|---------|
| `hasCompletedOnboarding` | Bool | Whether the user has seen and dismissed onboarding |
| `savedRadar` | JSON (SavedRadar) | Bluetooth peripheral UUID, display name, ID suffix, last connected date |

`SavedRadar` fields:
- `peripheralIdentifier` — `UUID` used to auto-connect on next scan
- `displayName` — human-readable name shown in Settings and RadarSelectionView
- `identifierSuffix` — last 4 characters of the UUID for compact display
- `lastConnectedAt` — `Date?` updated each time a connection succeeds

---

## Haptic Feedback Reference

| Event | Pattern |
|-------|---------|
| New vehicle threat | 4× `.retry` pulses, 0.3s apart (rate-limited: max 1 per second) |
| Radar disconnected unexpectedly | 1× `.failure` pulse |

Haptics are suppressed (`alertsEnabled = false`) while the EndRideSheet is shown to prevent distracting feedback during the end-ride decision.

---

## Bluetooth & HealthKit Details

**BLE Service UUID:** `6A4E3200-667B-11E3-949A-0800200C9A66` (Garmin Varia)

**Radar data packet format:** `[header][threatID][distance][speed]` — repeating 3-byte threat blocks after a 1-byte header. Single-byte packets indicate no threats.

**HealthKit workout type:** Outdoor Cycling (`HKWorkoutConfiguration.activityType = .cycling`)

**HealthKit permissions:** Write-only. The app saves workout records but does not read any Health data.

**Background execution:** The active `HKWorkoutSession` keeps the app running in the background during rides. Without it, watchOS would suspend the app and BLE characteristic notifications would stop.

---

## Simulator Behavior

The app includes simulator-specific code (`#if targetEnvironment(simulator)`) that:

- Skips HealthKit authorization (returns `true` immediately)
- Presents two fake devices: "Varia RTL515" and "Varia RTL516" with fixed UUIDs
- Auto-connects if one of those UUIDs is saved; otherwise shows the selection screen
- Simulates a new vehicle threat every 4 seconds
- Simulates an unexpected radar disconnect at the 20-second mark to exercise the reconnect flow
