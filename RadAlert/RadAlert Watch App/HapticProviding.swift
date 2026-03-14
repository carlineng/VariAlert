// SPDX-License-Identifier: MIT
//
//  HapticProviding.swift
//  RadAlert Watch App
//

import WatchKit

protocol HapticProviding {
    func play(_ hapticType: WKHapticType)
}

struct DeviceHapticProvider: HapticProviding {
    func play(_ hapticType: WKHapticType) {
        WKInterfaceDevice.current().play(hapticType)
    }
}
