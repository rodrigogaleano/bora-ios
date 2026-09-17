import Foundation
import Testing
@testable import Bora

struct RunSettingsStoreTests {
    private static let key = "run_settings"

    /// A throwaway suite per test keeps these from touching the simulator's real defaults.
    private func makeDefaults() -> UserDefaults {
        let suite = "RunSettingsStoreTests.\(UUID().uuidString)"
        UserDefaults().removePersistentDomain(forName: suite)
        return UserDefaults(suiteName: suite) ?? .standard
    }

    @Test func emptyStoreReturnsDefaults() {
        let store = UserDefaultsRunSettingsStore(defaults: makeDefaults())

        #expect(store.load() == RunSettings())
    }

    @Test func savedSettingsRoundTrip() {
        let defaults = makeDefaults()
        var settings = RunSettings()
        settings.isVoiceCueEnabled = false
        settings.isMetronomeEnabled = true
        settings.metronomeBPM = 185

        UserDefaultsRunSettingsStore(defaults: defaults).save(settings)

        #expect(UserDefaultsRunSettingsStore(defaults: defaults).load() == settings)
    }

    @Test func undecodableBlobFallsBackToDefaults() {
        let defaults = makeDefaults()
        defaults.set(Data("not json".utf8), forKey: Self.key)

        #expect(UserDefaultsRunSettingsStore(defaults: defaults).load() == RunSettings())
    }
}
