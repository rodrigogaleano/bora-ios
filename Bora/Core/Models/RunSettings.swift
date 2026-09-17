import Foundation

/// User-level audio/haptic preferences. Persisted as a single JSON blob by
/// `RunSettingsStoring`, and snapshotted into a run when it starts — changing settings
/// mid-run doesn't reconfigure an in-flight session.
struct RunSettings: Hashable, Codable {
    var isVoiceCueEnabled = true
    var isBeepEnabled = true
    var isHapticsEnabled = true
    var isMetronomeEnabled = false
    var metronomeBPM = 170

    static let bpmRange = 140...200
}
