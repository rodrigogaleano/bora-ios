import Foundation

/// User-level audio/haptic/tracking preferences. Persisted as a single JSON blob by
/// `RunSettingsStoring`, and snapshotted into a run when it starts — changing settings
/// mid-run doesn't reconfigure an in-flight session.
struct RunSettings: Hashable, Codable {
    var isVoiceCueEnabled = true
    var isBeepEnabled = true
    var isHapticsEnabled = true
    var isMetronomeEnabled = false
    var metronomeBPM = 170
    /// Relative to the metronome's full click level, so the slider only ever turns it down.
    var metronomeVolume = 0.5
    var gpsAccuracy = GPSAccuracy.balanced
    var isTransitionWarningEnabled = true
    var progressCheckpoints: Set<ProgressCheckpoint> = [.half]
    var isFinalStretchEnabled = true
    var isKilometerSplitEnabled = false
    var isRepSummaryEnabled = true

    var checkpointConfig: CheckpointConfig {
        CheckpointConfig(
            isTransitionWarningEnabled: isTransitionWarningEnabled,
            progress: progressCheckpoints,
            isFinalStretchEnabled: isFinalStretchEnabled,
            isKilometerSplitEnabled: isKilometerSplitEnabled,
            isRepSummaryEnabled: isRepSummaryEnabled
        )
    }

    static let bpmRange = 140...200
    /// Floor above zero on purpose: the toggle is how you turn the metronome off, and a
    /// silent-but-enabled metronome just looks broken.
    static let metronomeVolumeRange = 0.05...1.0
}

extension RunSettings {
    /// Every key is optional on read: a blob written by an older build predates newer
    /// fields, and failing the whole decode would silently reset the user's saved choices.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = RunSettings()
        isVoiceCueEnabled = try container.decodeIfPresent(Bool.self, forKey: .isVoiceCueEnabled)
            ?? defaults.isVoiceCueEnabled
        isBeepEnabled = try container.decodeIfPresent(Bool.self, forKey: .isBeepEnabled)
            ?? defaults.isBeepEnabled
        isHapticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .isHapticsEnabled)
            ?? defaults.isHapticsEnabled
        isMetronomeEnabled = try container.decodeIfPresent(Bool.self, forKey: .isMetronomeEnabled)
            ?? defaults.isMetronomeEnabled
        metronomeBPM = try container.decodeIfPresent(Int.self, forKey: .metronomeBPM)
            ?? defaults.metronomeBPM
        metronomeVolume = try container.decodeIfPresent(Double.self, forKey: .metronomeVolume)
            ?? defaults.metronomeVolume
        gpsAccuracy = try container.decodeIfPresent(GPSAccuracy.self, forKey: .gpsAccuracy)
            ?? defaults.gpsAccuracy
        isTransitionWarningEnabled = try container.decodeIfPresent(Bool.self, forKey: .isTransitionWarningEnabled)
            ?? defaults.isTransitionWarningEnabled
        progressCheckpoints = try container.decodeIfPresent(Set<ProgressCheckpoint>.self, forKey: .progressCheckpoints)
            ?? defaults.progressCheckpoints
        isFinalStretchEnabled = try container.decodeIfPresent(Bool.self, forKey: .isFinalStretchEnabled)
            ?? defaults.isFinalStretchEnabled
        isKilometerSplitEnabled = try container.decodeIfPresent(Bool.self, forKey: .isKilometerSplitEnabled)
            ?? defaults.isKilometerSplitEnabled
        isRepSummaryEnabled = try container.decodeIfPresent(Bool.self, forKey: .isRepSummaryEnabled)
            ?? defaults.isRepSummaryEnabled
    }
}
