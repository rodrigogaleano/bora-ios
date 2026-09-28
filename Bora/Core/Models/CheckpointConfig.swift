import Foundation

struct CheckpointConfig: Codable, Hashable {
    var isTransitionWarningEnabled = true
    var progress: Set<ProgressCheckpoint> = [.half]
    var isFinalStretchEnabled = true
    var isKilometerSplitEnabled = false
    var isRepSummaryEnabled = true
}
