import Foundation

struct CheckpointConfig: Hashable {
    var isTransitionWarningEnabled = true
    var progress: Set<ProgressCheckpoint> = [.half]
    var isFinalStretchEnabled = true
    var isKilometerSplitEnabled = false
}
