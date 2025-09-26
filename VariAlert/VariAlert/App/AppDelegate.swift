// SPDX-License-Identifier: MIT
//
//  AppDelegate.swift
//  VariAlert
//
//  Created by Carlin Eng on 2/2/25.
//

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    // This is only needed if you require advanced app lifecycle handling.
    // If you do not use it, remove any references to AppDelegate in your project.

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Perform any custom setup here
        return true
    }

    // MARK: UISceneSession Lifecycle
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration",
                                    sessionRole: connectingSceneSession.role)
    }
}
