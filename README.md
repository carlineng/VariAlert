// SPDX-License-Identifier: MIT

# VariAlert

A standalone Apple Watch app that connects directly to a Garmin Varia radar and delivers haptic alerts when vehicles approach from behind — no iPhone app required.

## Features

- Connects to Garmin Varia radar via Bluetooth directly from the watch
- Haptic alerts (4-pulse pattern) when new vehicles are detected
- Integrates with HealthKit to track cycling workouts
- Fully standalone — works without a companion iPhone app running

## Requirements

- Apple Watch (watchOS 10.5+)
- Garmin Varia radar device
- iPhone paired to the watch (required for initial Xcode installation; not required at runtime)
- Xcode 15.4+ for building

## Getting Started

1. Open `VariAlert/VariAlert.xcodeproj` in Xcode
2. Select the `VariAlertWatch Watch App` target
3. Under **Signing & Capabilities**, set your Development Team
4. Connect your iPhone via USB and select your Apple Watch as the run destination
5. Hit ⌘R to build and install

## Usage

1. Open the app on your Apple Watch
2. Tap **Start Ride** — this begins a HealthKit workout session and starts scanning for your Garmin Varia
3. Once the radar connects, the status shows **Radar Connected**
4. Ride — the watch will vibrate when vehicles approach from behind
5. Long-press **Pause Ride** to end the session

## Notes

- Apps signed with a free (personal) Apple Developer account expire after 7 days. A paid Apple Developer Program membership ($99/yr) is required for longer-lived installs.
- The app requires Bluetooth and HealthKit permissions on first launch.

---

## Disclaimer

This software is provided "AS IS", without warranty of any kind, express or implied,
including but not limited to the warranties of merchantability, fitness for a
particular purpose, and noninfringement. In no event shall the authors or
copyright holders be liable for any claim, damages, or other liability, whether
in an action of contract, tort, or otherwise, arising from, out of, or in
connection with the software or the use or other dealings in the software.

This project is **not** production-ready. No support, maintenance, or security
updates are promised. Use at your own risk.

## Maintenance & Support

No SLA. Issues and PRs may be ignored or closed without response.
There is no guarantee of updates or compatibility.

## Security

If you find a vulnerability, you may report it via Issues or email (optional).
We do not commit to remediation timelines or fixes. Use at your own risk.

## Contribution

By submitting a contribution, you agree it is your own work and you grant the
project a perpetual, worldwide, non-exclusive, royalty-free license to use it.
Contributions are provided "AS IS", without warranties or guarantees of inclusion.
