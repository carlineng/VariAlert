// SPDX-License-Identifier: MIT
//
//  RadarStoreProviding.swift
//  RadAlert Watch App
//

import Foundation

protocol RadarStoreProviding {
    func load() -> SavedRadar?
    func save(_ radar: SavedRadar)
    func delete()
}

struct UserDefaultsRadarStore: RadarStoreProviding {
    private let defaults: UserDefaults
    private let key = "savedRadar"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> SavedRadar? {
        guard let data = defaults.data(forKey: key),
              let radar = try? JSONDecoder().decode(SavedRadar.self, from: data) else { return nil }
        return radar
    }

    func save(_ radar: SavedRadar) {
        if let data = try? JSONEncoder().encode(radar) {
            defaults.set(data, forKey: key)
        }
    }

    func delete() {
        defaults.removeObject(forKey: key)
    }
}
