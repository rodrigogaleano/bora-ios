import Foundation

struct HIITPlan: Codable, Hashable {
    var sets: Int
    var work: BlockTarget
    var rest: BlockTarget
}

extension HIITPlan {
    var isValid: Bool {
        sets >= 1 && work.isValid && rest.isValid
    }
}

struct SessionPlan: Codable, Hashable {
    var goal: SessionGoal
    var warmup: BlockTarget?
    var hiit: HIITPlan?
    var cooldown: BlockTarget?
    var workoutType: WorkoutType?
    var checkpoints = CheckpointConfig()
}

extension SessionPlan {
    var isValid: Bool {
        goal.isValid
            && (warmup?.isValid ?? true)
            && (hiit?.isValid ?? true)
            && (cooldown?.isValid ?? true)
    }
}
