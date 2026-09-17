import Foundation

final class UserDefaultsRunSettingsStore: RunSettingsStoring {
    private static let key = "run_settings"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Falls back to defaults both when nothing was stored yet and when the stored blob
    /// can't be decoded — a settings payload written by an older build must never block
    /// the app from starting.
    func load() -> RunSettings {
        guard
            let data = defaults.data(forKey: Self.key),
            let settings = try? JSONDecoder().decode(RunSettings.self, from: data)
        else {
            return RunSettings()
        }
        return settings
    }

    func save(_ settings: RunSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
