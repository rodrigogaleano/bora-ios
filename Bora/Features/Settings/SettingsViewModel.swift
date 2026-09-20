import Foundation

@Observable
final class SettingsViewModel {
    private let store: RunSettingsStoring
    private let cuePlayer: RunCueProviding
    private let onDone: () -> Void

    var isVoiceCueEnabled: Bool { didSet { persist() } }
    var isBeepEnabled: Bool { didSet { persist() } }
    var isHapticsEnabled: Bool { didSet { persist() } }
    var isMetronomeEnabled: Bool { didSet { persist() } }
    var gpsAccuracy: GPSAccuracy { didSet { persist() } }
    var metronomeVolume: Double {
        didSet {
            let range = RunSettings.metronomeVolumeRange
            let clamped = min(max(metronomeVolume, range.lowerBound), range.upperBound)
            if clamped != metronomeVolume {
                metronomeVolume = clamped
                return
            }
            cuePlayer.setMetronomeVolume(metronomeVolume)
            persist()
        }
    }
    var metronomeBPM: Int {
        didSet {
            let clamped = min(max(metronomeBPM, RunSettings.bpmRange.lowerBound), RunSettings.bpmRange.upperBound)
            if clamped != metronomeBPM {
                metronomeBPM = clamped
                return
            }
            persist()
        }
    }

    init(store: RunSettingsStoring, cuePlayer: RunCueProviding, onDone: @escaping () -> Void) {
        self.store = store
        self.cuePlayer = cuePlayer
        self.onDone = onDone

        let settings = store.load()
        isVoiceCueEnabled = settings.isVoiceCueEnabled
        isBeepEnabled = settings.isBeepEnabled
        isHapticsEnabled = settings.isHapticsEnabled
        isMetronomeEnabled = settings.isMetronomeEnabled
        gpsAccuracy = settings.gpsAccuracy
        metronomeBPM = settings.metronomeBPM
        metronomeVolume = settings.metronomeVolume
    }

    var settings: RunSettings {
        RunSettings(
            isVoiceCueEnabled: isVoiceCueEnabled,
            isBeepEnabled: isBeepEnabled,
            isHapticsEnabled: isHapticsEnabled,
            isMetronomeEnabled: isMetronomeEnabled,
            metronomeBPM: metronomeBPM,
            metronomeVolume: metronomeVolume,
            gpsAccuracy: gpsAccuracy
        )
    }

    /// Plays one representative cue with the current toggles so the user isn't configuring
    /// blind. Tears the session down right after — this screen isn't a run.
    func testCues() {
        let settings = settings
        cuePlayer.prepare(settings: settings)
        cuePlayer.play(.phaseStarted(RunPhase.Kind.warmup.displayName))
        if settings.isMetronomeEnabled {
            cuePlayer.startMetronome(bpm: settings.metronomeBPM)
        }
    }

    func stopTestCues() {
        cuePlayer.teardown()
    }

    func done() {
        stopTestCues()
        onDone()
    }

    private func persist() {
        store.save(settings)
    }
}
