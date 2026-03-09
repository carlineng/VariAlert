// SPDX-License-Identifier: MIT
//
//  SavedRadar.swift
//  RadAlert Watch App
//

import Foundation

struct SavedRadar: Codable {
    let peripheralIdentifier: UUID
    var displayName: String?
    var identifierSuffix: String
    var lastConnectedAt: Date?

    private static let userDefaultsKey = "savedRadar"

    static func load() -> SavedRadar? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let radar = try? JSONDecoder().decode(SavedRadar.self, from: data) else { return nil }
        return radar
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: SavedRadar.userDefaultsKey)
        }
    }

    static func delete() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}

struct DiscoveredRadar: Identifiable {
    let id: UUID
    let name: String
    let rssi: Int
    let identifierSuffix: String
    var isSaved: Bool
}
