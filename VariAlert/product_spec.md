# Garmin Varia Apple Watch App

## Overview

This document outlines the requirements, user flows, and primary screen designs for an app that connects to a Garmin Varia cycling radar. The app's primary purpose is to vibrate the Apple Watch to alert cyclists when cars are approaching from behind. The Apple Watch portion itself does not need any user interface, the Watch just needs to vibrate when a car is detected.


**Requirements**

**Functional Requirements:**

1. **Garmin Varia Connection**:  
   * Establish a Bluetooth connection to the Garmin Varia radar.  
   * Continuously receive data about approaching vehicles.  
2. **Alert System**:  
   * Vibrate the Apple Watch any time a new vehicle is detected by the radar.  
   * Ensure vibration alerts function even if the app is not in the foreground.  
3. **iPhone+Apple Watch**:  
   * Bluetooth connection management should happen on the iPhone
   * The Apple Watch should receive "Time Sensitive" notifications when the vehicle is detected
4. **Modes**:  
   * "Connected" Mode: Vibrate the Apple Watch for every new vehicle detected by the radar.  
   * "Disconnected" Mode: Display options for connecting to a radar.  
5. **Battery Optimization**:  
   * Manage power consumption to ensure extended usage during long rides.  

**Non-Functional Requirements:**

1. **Performance**:  
   * Low latency for real-time alerts.  
   * Smooth connectivity with minimal disruptions.  
2. **Compatibility**:  
   * Support for the latest Apple Watch models with watchOS 10 or later.  
3. **Scalability**:  
   * Allow future integration with other Garmin devices.

**Major User Flows**

**1\. Onboarding and Setup:**

* **Step 1**: Launch the app for the first time.  
* **Step 2**: Grant necessary permissions (Bluetooth, notifications, etc.).  
* **Step 3**: Enter Disconnected Mode.

**2\. Connected Mode:**

* **Step 1**: Automatically connect to the Garmin Varia when the app is opened.  
* **Step 2**: Detect vehicles and send alerts (vibration and visual cues).  
* **Step 3**: Display real-time vehicle detection updates (e.g., distance, speed).  
* **Step 4**: Continue vibration alerts even when the app is not in the foreground.

**3\. Disconnected Mode:**

* **Step 1**: Display status indicating no radar is connected.  
* **Step 2**: Provide options to connect to a radar.  
* **Step 3**: Gracefully handle connection failures and timeouts.  
* **Step 4**: Transition to Connected Mode once a radar is connected.

**4\. Settings Management:**

* **Step 1**: Access settings from a button in Connected Mode  
* **Step 2**: Update device pairing or reconnect to the Garmin Varia.  
* **Step 3**: View battery status and application version info.

**5\. Disconnection Handling:**

* **Step 1**: Alert the user if the Garmin Varia disconnects.  
* **Step 2**: Provide steps to reconnect or troubleshoot.

**Primary Screens**

**1\. Connected Screen:**

* **Features**:  
  * Display basic information about the connected radar unit (e.g., model and battery life).  
  * Red border if vehicles are detected; green border if not.  
  * Show the number of vehicles detected in large, easily readable font.  
  * Include a link to the Settings screen.  
* **Design Notes**:  
  * Large, glanceable icons and text for easy readability.  
  * High contrast for visibility in sunlight.

**2\. Disconnected Screen:**

* **Features**:  
  * Display status indicating no radar is connected.  
  * Provide options to connect to a radar.  
  * Guide the user through troubleshooting or pairing steps if needed.  
* **Design Notes**:  
  * Large, glanceable text and icons for quick understanding.

**3\. Settings Screen:**

* **Features**:  
  * Manage device connections; allow disconnecting from currently connected devices  
  * Show device info (battery level, device info, signal strength)  
  * Show app information (e.g., version)

**Design Principles**

1. **Minimalist UI**:  
   * Prioritize essential information to avoid distractions.  
2. **Glanceability**:  
   * Ensure that all screens can be understood within a few seconds.  
3. **Safety First**:  
   * Design with the cyclist’s safety in mind, minimizing the need to interact with the app during rides.

## Details: Disconnected Screen

The Disconnected Screen is the default screen of the app when no radar is connected. It’s primary purpose is to allow the user to look for radar devices to connect to, display eligible radar devices, and allow the user to initiate a connection attempt to a radar device.

**UI Components**

**Header Section**

* **Button:**  
  * Text: “Search for Radars”  
  * **Behavior:**  
    * On tap:  
      * Text changes to “Searching...”  
      * Button becomes unclickable (dimmed)  
      * Initiates radar search  
      * Reverts to “Search for Radars” after search completion or timeout

**Results Section**

* Displays a vertical list of detected radars (if any), each as a button:  
  * **Default Text:** Radar’s unique ID (e.g., “Radar 1234”)  
  * **Behavior:**  
    * On tap:  
      * Text changes to “Connecting...”  
      * Button becomes unclickable  
      * Triggers connection to the selected radar  
      * Reverts to the radar’s unique ID if the connection fails or times out

**Error or Status Messages (Dynamic)**

1. **Radar Not Found:**  
* If no radars are detected after a search:  
  * Display message: “No radars found. Try again.”  
  * Include a Retry Search button below the message  
1. **Connection Timeout:**  
* If connecting to a radar takes too long (e.g., over 10 seconds):  
  * Display a toast message: “Connection timed out. Please try again.”  
  * Revert the radar button to its original state for retry  
1. **Search Timeout:**  
* If no radars are detected within the search timeout period (e.g., 10 seconds):  
  * Automatically end the search and revert the “Search for Radars” button to its clickable state  
  * Display message: “Search completed. No radars found.”

**Behavior and User Flows**

**Initial State**

* Display a single button: “Search for Radars”.

**Searching State**

* The “Search for Radars” button changes to “Searching...” and becomes dimmed.

**Radar Not Found State**

* If no radars are found:  
  * Display the message: “No radars found. Try again.”  
  * Include a Retry Search button below the message.

**Post-Search State**

* Detected radars are displayed as buttons with their unique IDs.  
* Users can tap a radar button to attempt a connection.

**Connection State**

* When a radar button is tapped:  
  * Button text changes to “Connecting...”  
  * Button becomes unclickable  
  * **If connection succeeds:**  
    * Transition to the Connected Screen  
  * **If connection fails:**  
    * Revert button text to its original state with the radar ID  
    * Display a toast message: “Connection failed. Please try again.”

**Edge Cases**

1. **Bluetooth Disabled:**  
* If Bluetooth is off:  
  * Display a message: “Bluetooth is off. Please enable it to search for radars.”  
  * Include a link to device settings.  
1. **Interrupted Search:**  
* If the app is interrupted (e.g., user switches apps) during a search:  
  * Automatically stop the search.  
  * Allow the user to restart by tapping “Search for Radars”.  
1. **Interrupted Connection:**  
* If the radar disconnects or goes out of range during a connection attempt:  
  * Revert the radar button to its original state.  
  * Display a toast message: “Connection lost. Please try again.”

**Toast Notifications**

* **Connection Failed:** “Connection failed. Please try again.”  
* **Search Timeout:** “Search completed. No radars found.”  
* **Connection Timeout:** “Connection timed out. Please try again.”

## Details: Connected Screen

The **Connected Screen** serves as the app's primary interface during active use. It is designed for clarity and ease of use, ensuring cyclists can quickly glance at critical information.  
**UI Components**

**Header Section**

1. **Radar Status:**  
   * Displays the radar model name, its battery percentage, and radar signal strength.  
     * **Example:** "Radar 1234 | 85% Battery | Strong Signal"  
   * Updates dynamically when the radar’s battery level or signal strength changes.  
2. **Settings Button:**  
   * Icon-only button (gear icon).  
   * **Behavior:**  
     * Tapping transitions to the Settings Screen.  
     * Haptic feedback provided upon tap.

**Main Detection Area**

1. **Vehicle Detection Indicator:**  
   * Central display for real-time vehicle detection.  
   * **Default State (No Vehicle):**  
     * Green circular border.  
     * Text: "0 vehicles"  
   * **Vehicle Detected State:**  
     * Red circular border.  
     * Text: Number of vehicles detected (e.g., “3 vehicles”).  
   * **Behavior:**  
     * Updates in real time to reflect changes (e.g., when vehicles pass or leave the radar’s range).

**Behavior and User Flows**

**Initial State (No Vehicles)**

* Green border around the detection area.  
* Text: "No vehicles detected."  
* Radar status: "Connected."

**Vehicle Detected**

1. Border changes to red.  
2. Vibration triggered.  
3. Detection area updates with:  
   * Number of vehicles detected.

**Radar Disconnection or Malfunction**

1. The app triggers a notification to alert the user.  
2. Automatically transitions to the Disconnected Screen.

**Haptic Feedback Overload Prevention**

To prevent annoyance, notifications are spaced out to no more than one every 1 second, even if multiple vehicles are detected in quick succession.  

## Details: Settings Screen

The settings screen is primarily for device management, and is only accessible when the app is connected to a radar. It should be accessible from the Connected Screen. It should allow the user to view details about their radar device, pause notifications, and disconnect from a connected radar.

**1\. Device Management**

**Connected Device**

* Display the currently connected Garmin Varia device.  
  * Show device details (model name, battery status, firmware version).  
  * Options to disconnect or switch devices.  
* Button to pair a new Garmin Varia radar.

**2\. Safety Settings**

**Quiet Mode**

* Toggle to mute alerts.

**3\. App Information**

**Version Information**

* Display app version and build number.

**Privacy Policy & Terms of Use**

* Link to relevant documents.

**Acknowledgments**

* List any libraries, partnerships, or contributions.

**Layout and Design Considerations**

* **Grouped Sections**: Use clear headers (e.g., "Alerts," "Device Management") for organization.  
* **Easy Navigation**: Include a back button and consistent placement for key actions.  
* **Accessible Language**: Use simple, intuitive descriptions for each setting.  
* **Minimalist Design**: Focus on clarity and reduce unnecessary clutter.


## Project Structure

Below is a high-level guide for creating the initial Garmin Varia Apple Watch + iPhone project in Xcode, followed by a recommended file structure. This structure uses **SwiftUI** on both iOS and watchOS for simplicity (you can adapt to UIKit if you prefer). You’ll also see details on the role of each file and the major classes/structs contained within, including how they depend on each other.

---

## Part 1: Step-by-Step Project Setup in Xcode

1. **Open Xcode**  
   - Make sure you have the latest stable version of Xcode installed, along with the iOS SDK (and watchOS SDK) you plan to target.

2. **Create a New Project**  
   - From the Xcode welcome screen (or by choosing **File > New > Project**), select **App** under the **iOS** tab.  
   - Click **Next**.

3. **Configure the Project Options**  
   - **Product Name**: e.g., `GarminVariaApp`  
   - **Team**: Your Apple Developer account/team (required for provisioning profiles).  
   - **Organization Identifier**: e.g., `com.yourcompany`.  
   - **Language**: Swift  
   - **Interface**: SwiftUI  
   - **Lifecycle**: SwiftUI App  
   - **Include Tests**: (Optional)  
   - Click **Next** and choose a location to save your project.

4. **Add an Apple Watch Target**  
   - In the newly created project, go to **File > New > Target**.  
   - Under **watchOS**, select **Watch App**. Click **Next**.  
   - Ensure **Interface** is **SwiftUI** and check **Include Notification Scene** if you’d like to handle watch notifications (you’ll likely want this to enable Time Sensitive notifications).  
   - Provide a product name, e.g. `GarminVariaWatchApp`, and confirm the other settings.  
   - Click **Finish**.  
   - Xcode will prompt to activate the new scheme for the Watch target; you can either activate or keep the iPhone scheme active for now.

5. **Enable Capabilities** (for Bluetooth, Background Modes, and Notifications)  
   - Select your **iOS App target** in the Project Navigator. Go to the **Signing & Capabilities** tab.  
     - **Background Modes**: Enable `Bluetooth LE accessories` or `Uses Bluetooth LE accessories` (depending on Xcode version). Also enable `Background fetch` or `Remote notifications` if you plan to handle updates while the app is backgrounded.  
     - **Push Notifications** (optional if you want to do local or push notifications).  
   - You may also need **HealthKit** or other capabilities in some scenarios—only enable what you actually need.

6. **Update App Group / Bundle Identifiers** (optional)  
   - If you want the iPhone app and watch app to share data using `App Groups` or `Watch Connectivity`, set that up under Signing & Capabilities.  

7. **Configure `Info.plist`**  
   - In your iOS target’s `Info.plist`, add usage descriptions for Bluetooth and notifications:  
     - `NSBluetoothAlwaysUsageDescription`  
     - `NSBluetoothPeripheralUsageDescription` (if needed)  
     - `NSUserTrackingUsageDescription` (only if you need it)  
     - `UNNotificationsUsageDescription` (for local notifications).  

8. **Build & Run**  
   - At this point, you can build your project (Cmd + B). It should succeed even though no real code is in place yet.  
   - You have a minimal iOS + watchOS SwiftUI structure ready to go.

---

## Part 2: Recommended Codebase Structure

Below is a sample file structure that implements the **Disconnected Screen**, **Connected Screen**, and **Settings Screen** on the iPhone, as well as a minimal watch extension that handles vibrations/alerts. You’ll see references to “ViewModels” (for app state management), “Managers” (for Bluetooth and connectivity), and SwiftUI views.

Feel free to adapt naming and folder organization to your preference.

```
GarminVariaApp
├── GarminVariaApp (iOS Target)
│   ├── App                             // Application entry point files
│   │   ├── GarminVariaApp.swift
│   │   └── AppDelegate.swift           (Optional if needed)
│   ├── Managers                        // Non-UI classes handling logic like Bluetooth, Watch Connectivity, etc.
│   │   ├── RadarBluetoothManager.swift
│   │   └── WatchConnectivityManager.swift
│   ├── Models                          // Data structures (e.g., RadarDevice)
│   │   └── RadarDevice.swift
│   ├── ViewModels                      // State + logic for each screen
│   │   ├── DisconnectedViewModel.swift
│   │   ├── ConnectedViewModel.swift
│   │   └── SettingsViewModel.swift
│   ├── Views                           // SwiftUI Views for iPhone
│   │   ├── ContentView.swift           // Main app entry, holds navigation logic
│   │   ├── DisconnectedView.swift
│   │   ├── ConnectedView.swift
│   │   └── SettingsView.swift
│   └── Resources                       // Assets, localized strings, etc.
│       └── ...
└── GarminVariaWatchApp (watchOS Target)
    ├── GarminVariaWatchApp.swift       // Main entry for watch app
    ├── NotificationController.swift     // (If using notifications)
    ├── Managers
    │   └── WatchHapticManager.swift    // Manages haptic feedback for alerts
    └── (Additional files if needed)
```

Below is a description of each file or group:

---

### iOS Target

#### 1. **`GarminVariaApp.swift`** (in `App/` folder)

- **What It Is**: The SwiftUI entry point for your iOS app.  
- **Major Classes/Structs**:  
  - `GarminVariaApp: App`  
    - Configures the root scene, sets up any environment objects or singletons.  
- **Key Logic**:  
  - Typically uses a `WindowGroup` to present `ContentView`.  
  - Can instantiate `RadarBluetoothManager` or `WatchConnectivityManager` as shared singletons or environment objects.  
- **Dependencies**:  
  - Relies on the `ContentView` for the initial UI.  
  - Potentially uses `RadarBluetoothManager` to maintain the Bluetooth connection if you attach it as an `@StateObject` or `@EnvironmentObject`.

#### 2. **`AppDelegate.swift`** (Optional)

- **What It Is**: If you need more traditional application lifecycle hooks (e.g., background tasks, push notifications in a non-SwiftUI approach), place them here.  
- **Major Classes/Structs**:  
  - `AppDelegate` conforming to `UIApplicationDelegate`.  
- **Key Logic**:  
  - Handling background mode events or Bluetooth continuing in background.  
- **Dependencies**:  
  - May reference your `RadarBluetoothManager` or watchers for app states.

#### 3. **`RadarBluetoothManager.swift`** (in `Managers/` folder)

- **What It Is**: Central place to manage Bluetooth scanning, connecting, reading data from the Garmin Varia radar.  
- **Major Classes/Structs**:  
  - `RadarBluetoothManager` (class or observable object).  
  - Possibly some helper structs for device states, connection states, etc.  
- **Key Logic**:  
  - **Scanning** for nearby Garmin Varia devices (using `CoreBluetooth`).  
  - **Connecting** to a selected device.  
  - **Monitoring** data from the device (vehicle detection events).  
  - **Disconnecting** gracefully.  
- **Dependencies**:  
  - Depends on CoreBluetooth framework (`import CoreBluetooth`).  
  - UI ViewModels (e.g. `DisconnectedViewModel`) subscribe to this manager for scanning/connection updates.  
  - `ConnectedViewModel` subscribes for real-time detection events.

#### 4. **`WatchConnectivityManager.swift`** (in `Managers/` folder)

- **What It Is**: Handles communication from iOS → watchOS using `WatchConnectivity` or notifications.  
- **Major Classes/Structs**:  
  - `WatchConnectivityManager` (class/observable object).  
- **Key Logic**:  
  - Sends messages or triggers notifications to the watch (Time Sensitive notifications for real-time alerts).  
  - Maintains session state if you rely on watch connectivity.  
- **Dependencies**:  
  - iOS WatchConnectivity framework (`import WatchConnectivity`).  
  - May be used by `RadarBluetoothManager` when a new vehicle is detected to trigger a watch haptic or notification.

#### 5. **`RadarDevice.swift`** (in `Models/` folder)

- **What It Is**: Data model representing a discovered or connected Garmin Varia device.  
- **Major Fields**:  
  - `id`: Unique ID or UUID of the radar.  
  - `name`: A user-friendly name (e.g., “Radar 1234”).  
  - `batteryLevel`: Battery percentage.  
  - `isConnected`: Boolean for connection status, etc.  
- **Key Logic**:  
  - Basic struct or class with no complex logic.  
- **Dependencies**:  
  - Used by both ViewModels and the `RadarBluetoothManager` to pass device info.

#### 6. **`DisconnectedViewModel.swift`** (in `ViewModels/` folder)

- **What It Is**: An ObservableObject providing logic/states for the Disconnected Screen.  
- **Major Properties**:  
  - `radarDevices: [RadarDevice]` – discovered radars.  
  - `isSearching: Bool`  
  - `errorMessage: String?` or state enumeration for errors/timeouts.  
- **Key Logic**:  
  - Kicks off scanning via `RadarBluetoothManager`.  
  - Handles user actions like “Search for Radars,” “Connect to Radar,” retry logic.  
  - Updates view state based on scan/connection results.  
- **Dependencies**:  
  - Strong reference to `RadarBluetoothManager`.  
  - Possibly references `WatchConnectivityManager` to coordinate watch state if needed.

#### 7. **`ConnectedViewModel.swift`** (in `ViewModels/` folder)

- **What It Is**: An ObservableObject providing logic/states for the Connected Screen.  
- **Major Properties**:  
  - `currentDevice: RadarDevice?`  
  - `vehicleCount: Int`  
  - `isVehicleDetected: Bool`  
- **Key Logic**:  
  - Subscribes to new vehicle detection events from `RadarBluetoothManager`.  
  - If a new vehicle is detected, triggers `WatchConnectivityManager` to vibrate the watch (or sends a local notification).  
  - Updates the UI with red/green border, vehicle count, etc.  
- **Dependencies**:  
  - `RadarBluetoothManager` for detection data.  
  - `WatchConnectivityManager` for watch notifications.

#### 8. **`SettingsViewModel.swift`** (in `ViewModels/` folder)

- **What It Is**: State + logic for the Settings Screen.  
- **Major Properties**:  
  - `currentDevice: RadarDevice?`  
  - `quietModeEnabled: Bool`  
  - `appVersion: String`  
- **Key Logic**:  
  - Toggling quiet mode (which might mute vibrations).  
  - Disconnecting from the radar.  
  - Providing device info (battery, firmware) from the manager.  
- **Dependencies**:  
  - `RadarBluetoothManager` for device connection/disconnection.  

#### 9. **`ContentView.swift`** (in `Views/` folder)

- **What It Is**: The top-level SwiftUI view for your iOS app.  
- **Major Classes/Structs**:  
  - `ContentView: View`  
- **Key Logic**:  
  - Decides whether to show the **DisconnectedView** or **ConnectedView** based on the app’s current state.  
  - Possibly uses an `@StateObject` or `@EnvironmentObject` referencing a global app state or manager.  
- **Dependencies**:  
  - `DisconnectedViewModel` and `ConnectedViewModel`.  
  - Observes `RadarBluetoothManager` or a combined global `AppViewModel`.

#### 10. **`DisconnectedView.swift`** (in `Views/` folder)

- **What It Is**: Implements all the UI details for the “Disconnected Screen” from your spec.  
- **Major Classes/Structs**:  
  - `DisconnectedView: View`  
- **Key Logic**:  
  - Has a button “Search for Radars.”  
  - Displays a list of found radars.  
  - Shows error messages, timeouts, etc.  
- **Dependencies**:  
  - `DisconnectedViewModel` to drive the state and user interactions.

#### 11. **`ConnectedView.swift`** (in `Views/` folder)

- **What It Is**: Implements the UI for the “Connected Screen.”  
- **Major Classes/Structs**:  
  - `ConnectedView: View`  
- **Key Logic**:  
  - Displays real-time vehicle detection.  
  - Shows green or red border, vehicle count.  
  - Includes a button to open Settings.  
- **Dependencies**:  
  - `ConnectedViewModel` for detection count and watch alerts.

#### 12. **`SettingsView.swift`** (in `Views/` folder)

- **What It Is**: UI for the “Settings Screen.”  
- **Major Classes/Structs**:  
  - `SettingsView: View`  
- **Key Logic**:  
  - Toggles quiet mode.  
  - Displays device info (model, battery, firmware).  
  - Option to disconnect or pair a new device.  
- **Dependencies**:  
  - `SettingsViewModel`.

---

### watchOS Target

Because the Apple Watch portion of your specification is minimal (largely haptics and background alerts), you can keep it lightweight.

#### 1. **`GarminVariaWatchApp.swift`**

- **What It Is**: The SwiftUI entry point for the Watch app.  
- **Major Classes/Structs**:  
  - `GarminVariaWatchApp: App`  
- **Key Logic**:  
  - In watchOS 10 and SwiftUI, you can define your main scene here.  
  - You may not need any visible UI if you’re purely sending haptics/notifications in the background.

#### 2. **`NotificationController.swift`** (Generated by Xcode if you added a Notification Scene)

- **What It Is**: Handles inbound notifications on the watch.  
- **Logic**:  
  - If you’re sending “Time Sensitive” local or push notifications to the watch, you can customize how they appear or handle them here.

#### 3. **`WatchHapticManager.swift`** (in `Managers/` folder under the Watch target)

- **What It Is**: A small manager to play haptic feedback on the watch.  
- **Major Classes/Structs**:  
  - `WatchHapticManager`  
- **Key Logic**:  
  - Calls `WKInterfaceDevice.current().play(.notification)` or similar to provide haptic feedback.  
- **Dependencies**:  
  - The watch’s APIs (`import WatchKit`).  
- **Usage**:  
  - When iOS side notifies the watch of a new vehicle, a local notification or WatchConnectivity message is received, triggering `WatchHapticManager` to provide haptic feedback.

---

## Putting It All Together

1. **Start with the iPhone App**  
   - Implement `RadarBluetoothManager` so you can scan and connect to Garmin Varia devices.  
   - Build `DisconnectedView` + `DisconnectedViewModel` to handle your search → connect flow.  
   - Build `ConnectedView` + `ConnectedViewModel` to show real-time data and handle transitions.  

2. **Integrate WatchConnectivity**  
   - Implement `WatchConnectivityManager` to send messages or schedule local notifications on the watch.  
   - Decide if you want local notifications or direct messages. Local “Time Sensitive” notifications might be easiest to ensure the user always receives the alert, even if the watch app is not in the foreground.

3. **Implement the Watch App**  
   - If minimal UI is needed, the watch target can remain mostly empty except for haptic and notification handling.  
   - Test your flows: when a new vehicle is detected on iPhone, the watch should vibrate almost instantly.

4. **Add the Settings Screen**  
   - Build out `SettingsView` + `SettingsViewModel` for toggling quiet mode, checking battery, version info, etc.

5. **Finalize and Test**  
   - Ensure background modes are properly set so that the user can receive alerts when the iPhone is locked or your app is in the background.  
   - Test with real hardware (iPhone + Apple Watch + Garmin Varia Radar) to confirm connections and haptic alerts.

