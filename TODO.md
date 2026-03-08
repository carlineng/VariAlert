# RadAlert TODO

## Completed

### Standalone watchOS Refactor
- [x] Create watchOS `BluetoothManager.swift` (BLE scanning, auto-connect, threat parsing + dedup, haptic alerts)
- [x] Update `WatchAppState.swift` — add `isRadarConnected` property
- [x] Replace `WatchConnectivityManager` with `BluetoothManager` at app entry point
- [x] Delete `WatchConnectivityManager.swift` from watchOS target
- [x] Update Xcode project file — added BluetoothManager to watchOS Sources, removed WatchConnectivityManager
- [x] Add `NSBluetoothAlwaysUsageDescription` to watchOS build settings
- [x] Fix HealthKit entitlements — removed `healthkit.access` (Health Records), kept basic `healthkit`
- [x] Remove iOS app and test targets entirely
- [x] Configure watch as standalone (`WKRunsIndependentlyOfCompanionApp = YES`)

### Development Experience
- [x] **Simulator support** — `BluetoothManager` uses `#if targetEnvironment(simulator)` to simulate radar connection (2s delay), periodic fake threats (every 4s), and an unexpected disconnect (at 20s) without any BLE hardware
- [x] **Visual threat indicator** — red border flashes on `WorkoutView` when a threat is detected, making haptic events visible in the simulator
- [x] **Stub iOS companion app** (`VariAlertStub`) — prevents watchOS from orphan-cleaning the watch app during local development; includes step-by-step removal instructions

### Reliability & Safety UX
- [x] **Radar disconnect notification** — unexpected mid-ride disconnect plays `.failure` haptic, flashes orange border, shows "Radar Lost" status, then auto-retries scanning after 2s; explicit stop does not trigger the alert
- [x] **Scan retry** — 15s scan timeout stops a stalled scan; "Scan Again" button appears whenever not connected and not scanning

### Workout UX
- [x] **Long-press → confirmation screen** — Resume / End and Save / End and Discard; visual hierarchy green/secondary/destructive
- [x] **End and Save** — persists `HKWorkout` via `HKWorkoutBuilder.finishWorkout()`
- [x] **End and Discard** — calls `discardWorkout()`; no data saved
- [x] **Haptic alerts suppressed during confirmation** — `bluetoothManager.alertsEnabled = false` while sheet is shown
- [x] **Session expiry handling** — `onSessionExpired` callback returns app to idle if watchOS unexpectedly ends the session
- [x] **Elapsed Time stopwatch** — MM:SS (H:MM:SS after 60 min) replaces time-of-day clock
- [x] **Vehicle Count** — cumulative session total; resets on new ride
- [x] **"Long press to stop" hint** — caption label below Stop button

### App Naming & Branding
- [x] **Rename app and project** — renamed to **RadAlert** (subtitle: "Radar Alerts for Cyclists")
- [x] **Rename GitHub repo** — renamed to `RadAlert` on GitHub; local remote URL updated
- [x] **Rename "Idle State" label** — changed to "RadAlert"

### Legal & Compliance
- [x] **In-app disclaimer screen** — `DisclaimerView.swift`; shown on first launch; gated in `ContentView` via `@AppStorage("hasAcknowledgedDisclaimer")`
- [x] **App Store description disclaimer** — safety/liability text; see Notes below
- [x] **Privacy policy** — `docs/privacy.html`; served via GitHub Pages at https://carlineng.github.io/RadAlert/privacy.html

---

## App Store Readiness

### Prerequisites
- [ ] **Paid Apple Developer Program membership** ($99/yr) — required to submit to App Store; personal/free team cannot submit
- [ ] **Remove VariAlertStub iOS target** — must be removed before App Store submission (Apple guideline 4.2); removal requires paid account so App Store distribution manages watch app persistence instead; see `VariAlertStub/StubApp.swift` for instructions
- [x] **Enable GitHub Pages** — live at https://carlineng.github.io/RadAlert/privacy.html

### Core UX / App Review Requirements
- [ ] **Onboarding + permission flow** — 3-page TabView (what it does / what you need / safety notice); "Get Started" triggers BT + HK permission requests; replaces `DisclaimerView`; persisted via `@AppStorage("hasCompletedOnboarding")`
  - Page 1: app description
  - Page 2: hardware needed (Garmin Varia) + why Bluetooth and HealthKit are required
  - Page 3: safety disclaimer + "Get Started" button
- [ ] **Bluetooth permission denial handling** — `BluetoothDeniedView` (inline in RadAlertApp.swift); shown when `bluetoothState == .unauthorized`; instructs user to enable in iPhone Settings → Privacy & Security → Bluetooth; defer `CBCentralManager` init until "Get Started" so BT prompt fires after onboarding
- [ ] **HealthKit permission denial handling** — `HealthKitDeniedView` (inline in RadAlertApp.swift); shown when HK status is `.sharingDenied`; instructs user to enable in iPhone Settings → Health → Data Access & Devices
- [ ] **ContentView routing** — gate on: onboarding complete → BT state known → BT authorized → HK authorized → idle/workout
- [ ] **Remove `DisclaimerView.swift`** — content absorbed into onboarding page 3; remove from project.pbxproj

#### Implementation details
- `BluetoothManager`: move `CBCentralManager` init to `initialize()` method; add `@Published var bluetoothState: CBManagerState = .unknown`; add `var isAuthorized: Bool` computed property
- `WorkoutSessionManager`: extract HK auth request into `requestAuthorization(completion:)`; add `var isHealthKitAuthorized: Bool` (synchronous status check)
- Simulator path: `initialize()` sets `bluetoothState = .poweredOn` immediately

### Polish
- [ ] **App icon** — required for App Store submission
- [ ] **Version and build number** — set appropriately before submission
- [ ] **Screenshot(s)** — App Store requires at least one Apple Watch screenshot

### App Store Connect Setup
- [ ] Create app record in App Store Connect
- [ ] Configure HealthKit data types in App Store Connect (required when using HealthKit entitlement)
- [ ] Write App Store description, keywords, and support URL
- [ ] Link privacy policy URL (https://carlineng.github.io/RadAlert/privacy.html)

---

## Notes
- Workout session (`HKWorkoutSession` + `HKLiveWorkoutBuilder`) maintains background execution and optionally saves ride data to Apple Health
- Haptic alerts only fire during active workout mode; suppressed during end-of-ride confirmation sheet
- Auto-connect to first discovered Garmin Varia (no manual device selection)
- Haptic pattern: 4× `.retry` pulses, 0.3s spacing
- `VariAlertStub` iOS target exists only to satisfy the companion app check during development; see `VariAlertStub/StubApp.swift` for removal instructions
- `WKCompanionAppBundleIdentifier = com.carlineng.RadAlert` is required by WatchKit installer (bundle ID prefix constraint); remove when removing the stub

### App Store Description Disclaimer
> SAFETY NOTICE: RadAlert is a supplemental awareness tool and is not a certified safety device. It cannot guarantee detection of all vehicles. Always follow traffic laws, remain alert, and rely on your own judgement while riding. The developer assumes no liability for accidents or injuries. Use at your own risk.

### App Store Keywords
garmin varia, cycling radar, bike radar, haptic alert, bicycle safety
