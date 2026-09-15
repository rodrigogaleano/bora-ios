import Foundation

struct HIITPlan: Hashable {
    var sets: Int
    var work: BlockTarget
    var rest: BlockTarget
}

extension HIITPlan {
    var isValid: Bool {
        sets >= 1 && work.isValid && rest.isValid
    }
}

struct SessionPlan: Hashable {
    var goal: SessionGoal
    var warmup: BlockTarget?
    var hiit: HIITPlan?
    var cooldown: BlockTarget?
}

extension SessionPlan {
    var isValid: Bool {
        goal.isValid
            && (warmup?.isValid ?? true)
            && (hiit?.isValid ?? true)
            && (cooldown?.isValid ?? true)
    }
}
