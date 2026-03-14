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
- [x] **Explicit disconnect cleanup** — ending a ride now stops active BLE scans as well as peripheral connections
- [x] **Background-safe workout view** — leaving the workout screen no longer automatically disconnects the radar
- [x] **Threat haptic cooldown** — suppresses overlapping 4-pulse alerts within a 1s cooldown window

### Workout UX
- [x] **Long-press → confirmation screen** — Resume / End and Save / End and Discard; visual hierarchy green/secondary/destructive
- [x] **End and Save** — persists `HKWorkout` via `HKWorkoutBuilder.finishWorkout()`
- [x] **End and Discard** — calls `discardWorkout()`; no data saved
- [x] **Haptic alerts suppressed during confirmation** — `bluetoothManager.alertsEnabled = false` while sheet is shown
- [x] **Session expiry handling** — `onSessionExpired` callback returns app to idle if watchOS unexpectedly ends the session
- [x] **Workout start gating** — app only enters workout UI after `HKWorkoutSession` startup succeeds
- [x] **Elapsed Time stopwatch** — MM:SS (H:MM:SS after 60 min) replaces time-of-day clock
- [x] **Stable elapsed timer** — ride duration derives from `workoutStartDate` so it survives view recreation
- [x] **Vehicle Count** — cumulative session total; resets on new ride
- [x] **"Long press to stop" hint** — caption label below Stop button

### Radar Device Selection
- [x] **`SavedRadar` model** — Codable, UserDefaults persistence (`peripheralIdentifier`, `displayName`, `identifierSuffix`, `lastConnectedAt`)
- [x] **`DiscoveredRadar` struct** — value type with id, name, rssi, identifierSuffix, isSaved
- [x] **`BluetoothManager` updates** — `@Published var discoveredDevices`, `savedRadar`; collect peripherals on scan; auto-connect only to saved radar; `saveRadar()`, `saveAndConnect()`, `forgetSavedRadar()`, `connect(to:)`
- [x] **`RadarSelectionView`** — 4 states: scanning / empty / single-confirm / multi-list; Connect + Rescan + Cancel
- [x] **`SettingsView`** — radar name/ID/last connected; Change Radar + Forget Radar
- [x] **`IdleView`** — settings gear button when saved radar exists; Start Ride routes through RadarSelectionView if no saved radar
- [x] **`WorkoutView`** — fallback buttons when scan timed out (Keep Searching / New Radar / Cancel Ride); mid-ride radar swap via RadarSelectionView sheet
- [x] **Simulator** — simulates 2 discovered devices (Varia RTL515 + RTL516); auto-connects if one matches saved radar

### App Naming & Branding
- [x] **Rename app and project** — renamed to **RadAlert** (subtitle: "Radar Alerts for Cyclists")
- [x] **Rename GitHub repo** — renamed to `RadAlert` on GitHub; local remote URL updated
- [x] **Rename "Idle State" label** — changed to "RadAlert"

### Legal & Compliance
- [x] **In-app disclaimer screen** — absorbed into `OnboardingView.swift` page 3; gated via `@AppStorage("hasCompletedOnboarding")`
- [x] **App Store description disclaimer** — safety/liability text; see Notes below
- [x] **Privacy policy** — `docs/privacy.html`; served via GitHub Pages at https://carlineng.github.io/RadAlert/privacy.html

---

---

## App Store Readiness

### Hard Blockers

- [ ] **Update to watchOS 26 SDK / latest Xcode** — Apple requires watchOS 26 SDK for all uploads after April 28, 2026 (~7 weeks away); submission will be blocked at upload regardless of review; rebuild and re-test BLE + HealthKit flows on shipping OS after update
- [x] **Paid Apple Developer Program membership** ($99/yr) — required to submit to App Store; personal/free team cannot submit
- [x] **Remove VariAlertStub iOS target** — removed; `WKCompanionAppBundleIdentifier` key retained in build settings (required by watchOS simulator installer even without a companion app)

### Code Fixes (actionable now)

- [x] **Remove heart rate read permission** — `requestAuthorization()` now passes empty `typesToRead` set; only workout sharing is requested
- [x] **Add in-app privacy policy link** — `Link` in `IdleView` opens https://carlineng.github.io/RadAlert/privacy.html
- [x] **Tone down onboarding safety copy** — page 1 now reads "Provides supplemental haptic alerts from your Garmin Varia radar when vehicles approach from behind"

### Polish
- [ ] **App icon** — required for App Store submission
- [ ] **Version and build number** — set to `1.0` / `1` in Xcode target General tab before submission
- [ ] **Screenshot(s)** — App Store requires at least one Apple Watch screenshot

### App Store Connect Setup
- [ ] Create app record in App Store Connect
- [ ] Complete App Privacy form — must accurately reflect data practices (workout data written to Health on save; Bluetooth used for radar only; no analytics/ads/external transmission)
- [ ] Configure HealthKit data types in App Store Connect (required when using HealthKit entitlement)
- [ ] Write App Store description, keywords, and support URL — keep Garmin Varia references descriptive not promotional; say "Works with supported Garmin Varia radar devices" and list tested models (RTL 515, RTL 516)
- [ ] Link privacy policy URL (https://carlineng.github.io/RadAlert/privacy.html)
- [ ] **Write App Review notes** — explain hardware dependency; list exact test path for reviewer without hardware (simulator mode with fake threats); note app is an accessory-style interface for supported radar hardware and is not represented as a safety certification

### GitHub Pages
- [x] **Enable GitHub Pages** — live at https://carlineng.github.io/RadAlert/privacy.html

### Core UX / App Review Requirements
- [x] **Onboarding + permission flow** — `OnboardingView.swift`; 3-page TabView (what it does / what you need / safety notice); "Get Started" calls `bluetoothManager.initialize()` + `workoutManager.requestAuthorization`; persisted via `@AppStorage("hasCompletedOnboarding")`
- [x] **Bluetooth permission denial handling** — `BluetoothDeniedView` (inline in RadAlertApp.swift); shown when `bluetoothState == .unauthorized`; instructs user to enable in iPhone Settings → Privacy & Security → Bluetooth; `CBCentralManager` init deferred to "Get Started"
- [x] **HealthKit permission denial handling** — `HealthKitDeniedView` (inline in RadAlertApp.swift); shown when HK status is not `.sharingAuthorized`; instructs user to enable in iPhone Settings → Health → Data Access & Devices
- [x] **ContentView routing** — onboarding → BT unknown (spinner) → BT denied → HK denied → idle/workout

---

## Notes
- Workout session (`HKWorkoutSession` + `HKLiveWorkoutBuilder`) maintains background execution and optionally saves ride data to Apple Health
- Haptic alerts only fire during active workout mode; suppressed during end-of-ride confirmation sheet
- Auto-connect to first discovered Garmin Varia (no manual device selection)
- Haptic pattern: 4× `.retry` pulses, 0.3s spacing
### App Store Description Disclaimer
> SAFETY NOTICE: RadAlert is a supplemental awareness tool and is not a certified safety device. It cannot guarantee detection of all vehicles. Always follow traffic laws, remain alert, and rely on your own judgement while riding. The developer assumes no liability for accidents or injuries. Use at your own risk.

### App Store Keywords
cycling radar, bike radar, haptic alert, bicycle safety, garmin varia compatible
