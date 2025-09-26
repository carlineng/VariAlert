# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VariAlert is an iOS/watchOS application for Garmin Varia radar device integration. The project consists of:

- **iOS App**: Main iPhone application for radar device connection and management
- **watchOS App**: Apple Watch companion app for haptic alerts during cycling workouts
- **Shared Components**: Bluetooth connectivity and Watch Connectivity frameworks

## Build & Test Commands

### Building the Project
- Open `VariAlert/VariAlert.xcodeproj` in Xcode
- Build targets: `VariAlert` (iOS), `VariAlertWatch Watch App` (watchOS), `VariAlertTests` (unit tests)
- Use standard Xcode build commands (⌘+B) or xcodebuild CLI

### Running Tests
- Use Xcode Test Navigator or ⌘+U to run unit tests
- Tests are located in `VariAlertTests/` directory
- Mock Bluetooth components are available for testing in `MockBluetooth.swift`

### Development Requirements
- Xcode 15.4 or later
- iOS 17.5+ deployment target
- watchOS 10.5+ deployment target
- Swift 5.0
- Apple Developer account for device testing and App Store distribution

### Setup Instructions
1. Open `VariAlert/VariAlert.xcodeproj` in Xcode
2. Select the project in the navigator
3. For each target (VariAlert, VariAlertWatch Watch App, VariAlertTests):
   - Go to "Signing & Capabilities" tab
   - Set your Development Team (Apple ID/Developer Account)
   - Verify bundle identifiers are unique for your account

## Architecture Overview

### Core Design Pattern
The app follows MVVM architecture with SwiftUI and Combine:

**Models**
- `RadarDevice`: Represents Garmin Varia radar hardware
- `Threat`: Vehicle detection data from radar

**ViewModels**
- `AppStateViewModel`: Global app state (connected/disconnected)
- `DisconnectedViewModel`: Bluetooth scanning and device discovery
- `ConnectedViewModel`: Active radar monitoring and threat processing
- `SettingsViewModel`: Device configuration and quiet mode

**Managers**
- `BluetoothManager`: Core Bluetooth communication with Garmin Varia
- `WatchConnectivityManager`: iOS ↔ watchOS message passing

### Data Flow
1. **Discovery**: BluetoothManager scans for Garmin service UUID `6A4E3200-667B-11E3-949A-0800200C9A66`
2. **Connection**: Establishes connection and discovers characteristics
3. **Monitoring**: Receives threat data, parses into Threat objects
4. **Alerting**: New threats trigger Watch Connectivity messages
5. **Watch Response**: watchOS app provides haptic feedback during workouts

### Key Implementation Details

**Bluetooth Communication**
- Service UUID: `6A4E3200-667B-11E3-949A-0800200C9A66`
- Threat data parsing in `parseRadarData()`: payload format is `[header][threatID][distance][speed]...`
- Automatic threat deduplication using `Set<UInt8>` tracking

**Watch Integration**
- Haptic alerts only active during workout sessions (`WatchAppState.mode == .workout`)
- HealthKit integration for workout session management
- Four-pulse haptic pattern using `.retry` haptic type

**State Management**
- `@Published` properties with Combine for reactive updates
- Central `AppStateViewModel` coordinates connection state
- Environment objects pass dependencies through SwiftUI view hierarchy

## Testing Approach

The codebase includes unit tests with Bluetooth mocking:
- `BluetoothManagerTests.swift`: Core Bluetooth functionality testing
- `MockBluetooth.swift`: CBCentralManager and peripheral mocking
- Tests cover scanning, connection, disconnection, and data parsing

Missing test wrapper: `MockPeripheralWrapper` class referenced in tests but not implemented.

## Development Notes

- Bluetooth permissions required: `NSBluetoothAlwaysUsageDescription`, `NSBluetoothPeripheralUsageDescription`, `NSBluetoothWhileInUseUsageDescription`
- HealthKit permissions required for watch workout sessions
- Watch Connectivity handles real-time communication between iOS and watchOS targets
- Threat detection uses distance-based algorithms with configurable thresholds