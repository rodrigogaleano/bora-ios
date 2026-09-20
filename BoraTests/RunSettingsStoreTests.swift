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
        settings.metronomeVolume = 0.15
        settings.gpsAccuracy = .economy

        UserDefaultsRunSettingsStore(defaults: defaults).save(settings)

        #expect(UserDefaultsRunSettingsStore(defaults: defaults).load() == settings)
    }

    @Test func undecodableBlobFallsBackToDefaults() {
        let defaults = makeDefaults()
        defaults.set(Data("not json".utf8), forKey: Self.key)

        #expect(UserDefaultsRunSettingsStore(defaults: defaults).load() == RunSettings())
    }

    @Test func blobFromBeforeGpsAccuracyKeepsSavedChoicesAndDefaultsTheNewField() {
        let defaults = makeDefaults()
        let legacy = """
        {"isVoiceCueEnabled":false,"isBeepEnabled":true,"isHapticsEnabled":false,
        "isMetronomeEnabled":true,"metronomeBPM":180}
        """
        defaults.set(Data(legacy.utf8), forKey: Self.key)

        let loaded = UserDefaultsRunSettingsStore(defaults: defaults).load()

        #expect(!loaded.isVoiceCueEnabled)
        #expect(!loaded.isHapticsEnabled)
        #expect(loaded.isMetronomeEnabled)
        #expect(loaded.metronomeBPM == 180)
        #expect(loaded.gpsAccuracy == .balanced)
        #expect(loaded.metronomeVolume == RunSettings().metronomeVolume)
    }
}
