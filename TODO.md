# RadAlert TODO

## Completed (Standalone watchOS Refactor)
- [x] Create watchOS `BluetoothManager.swift` (BLE scanning, auto-connect, threat parsing + dedup, haptic alerts)
- [x] Update `WatchAppState.swift` — add `isRadarConnected` property
- [x] Update `VariAlertWatchApp.swift` — replace `WatchConnectivityManager` with `BluetoothManager`
- [x] Delete `WatchConnectivityManager.swift` from watchOS target
- [x] Update `WorkoutView.swift` — start scanning on appear, show connection status, disconnect on stop
- [x] Update Xcode project file — added BluetoothManager to watchOS Sources, removed WatchConnectivityManager
- [x] Add `NSBluetoothAlwaysUsageDescription` to watchOS build settings
- [x] Fix HealthKit entitlements — removed `healthkit.access` (Health Records), kept basic `healthkit`
- [x] Remove iOS app and test targets entirely
- [x] Configure watch as standalone (`WKRunsIndependentlyOfCompanionApp = YES`)
- [x] Update CLAUDE.md and README

## Completed (Development Experience)
- [x] **Simulator support** — `BluetoothManager` uses `#if targetEnvironment(simulator)` to simulate radar connection (2s delay), periodic fake threats (every 4s), and an unexpected disconnect (at 20s) without any BLE hardware
- [x] **Visual threat indicator** — red border flashes on `WorkoutView` when a threat is detected, making haptic events visible in the simulator
- [x] **Stub iOS companion app** (`VariAlertStub`) — prevents watchOS from orphan-cleaning the watch app during local development; includes step-by-step removal instructions

## Completed (Reliability & Safety UX)
- [x] **Radar disconnect notification** — unexpected mid-ride disconnect plays `.failure` haptic, flashes orange border, shows "Radar Lost" status, then auto-retries scanning after 2s; explicit "Pause Ride" stop does not trigger the alert
- [x] **Scan retry** — 15s scan timeout stops a stalled scan; "Scan Again" button appears whenever not connected and not scanning

---

## Workout UX Improvements

### End-of-Ride Confirmation Flow
- [x] **Long-press → confirmation screen** — replace direct "Pause Ride" action with a confirmation screen showing three options: **Resume**, **End and Save**, **End and Discard**
  - Resume: return to active ride, haptic alerts resume
  - End and Save: save `HKWorkout` (cycling, with start/end time and duration) via `HKWorkoutBuilder`, then return to idle
  - End and Discard: call `discard()` on the workout builder, return to idle
  - Visual hierarchy: Resume = primary/green, End and Save = secondary, End and Discard = destructive/red
- [x] **Haptic alerts suppressed during confirmation screen** — `bluetoothManager.alertsEnabled = false` while sheet is shown; restored on Resume
- [x] **Session expiry handling** — `WorkoutSessionManager.onSessionExpired` callback fires on unexpected session end; WorkoutView returns to idle

### WorkoutView Metrics
- [x] **Replace time-of-day with Elapsed Time** — 1-second timer drives MM:SS stopwatch (switches to H:MM:SS after 60 minutes)
- [x] **Vehicle Count** — cumulative total tracked in `BluetoothManager.vehicleCount`; increments on new threats, resets on `startScanning()`
- [x] **"Long press to stop" hint** — caption label below Stop button

### HealthKit Integration
- [x] **Wire up `HKWorkoutBuilder`** — `endAndSave()` calls `finishWorkout()`; `endAndDiscard()` calls `discardWorkout()`; both paths clear `workoutStartDate`

---

## App Store Readiness

### Prerequisites
- [ ] **Paid Apple Developer Program membership** ($99/yr) — required to submit to App Store; personal/free team cannot submit
- [ ] **Remove VariAlertStub iOS target** — the `VariAlertStub/` iOS app is a development workaround to prevent watchOS from orphan-cleaning the watch app (see `VariAlertStub/StubApp.swift` for step-by-step removal instructions); it must be removed before App Store submission as Apple will reject a stub iOS app under guideline 4.2 (Minimum Functionality); removal requires a paid developer account so App Store distribution manages watch app persistence instead
- [x] **Rename the app and project** — renamed to **RadAlert** (subtitle: "Radar Alerts for Cyclists"); App Store keywords to include: "garmin varia, cycling radar, bike radar, haptic alert"
- [x] **Rename GitHub repo** — renamed to `RadAlert` on GitHub; local remote URL updated

### Legal & Compliance
- [x] **In-app disclaimer screen** — `DisclaimerView.swift`; shown on first launch via `@AppStorage("hasAcknowledgedDisclaimer")`; gated in `ContentView` before idle/workout views
- [x] **App Store description disclaimer** — see text below in Notes
- [x] **Privacy policy** — `docs/privacy.html` in repo; enable GitHub Pages from `docs/` on `main` at https://carlineng.github.io/RadAlert/privacy.html; link this URL in App Store Connect

### Core UX / App Review Requirements
- [ ] **Onboarding flow** — explain what the app does and what hardware is needed (Garmin Varia) before the user hits the main screen
- [ ] **Bluetooth permission denial handling** — if user denies Bluetooth, show an actionable message explaining why it's needed and how to enable it in Settings (currently the app silently does nothing)
- [ ] **HealthKit permission denial handling** — if user denies HealthKit, either gracefully degrade (no workout tracking) or explain why it's required
- [x] **Rename "Idle State" label** — changed to "RadAlert"

### Reliability & Safety UX
- [x] **Workout metrics** — elapsed time + vehicle count displayed; workout saved to HealthKit on "End and Save"

### Polish
- [ ] **App icon** — required for App Store submission
- [x] **App name** — "RadAlert" (display name set in build settings)
- [ ] **Version and build number** — set appropriately before submission
- [ ] **Screenshot(s)** — App Store requires at least one Apple Watch screenshot

### App Store Connect Setup
- [ ] Create app record in App Store Connect
- [ ] Configure HealthKit data types in App Store Connect (required when using HealthKit entitlement)
- [ ] Write App Store description, keywords, and support URL
- [ ] Link privacy policy URL

---

## Notes
- Workout session (`HKWorkoutSession`) is kept to maintain background execution during rides
- Haptic alerts only fire during active workout mode
- Auto-connect to first discovered Garmin Varia (no manual device selection)
- Haptic pattern: 4× `.retry` pulses, 0.3s spacing
- `VariAlertStub` iOS target exists only to satisfy the companion app check and prevent watch app orphan-cleanup during development; see `VariAlertStub/StubApp.swift` for removal instructions
- `WKCompanionAppBundleIdentifier = com.carlineng.RadAlert` is required by WatchKit installer (bundle ID prefix constraint) and must match the stub's bundle ID; remove both when removing the stub

### App Store Description Disclaimer (paste into App Store Connect description)
> SAFETY NOTICE: RadAlert is a supplemental awareness tool and is not a certified safety device. It cannot guarantee detection of all vehicles. Always follow traffic laws, remain alert, and rely on your own judgement while riding. The developer assumes no liability for accidents or injuries. Use at your own risk.
