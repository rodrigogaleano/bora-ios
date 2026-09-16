import Foundation

enum RunPhase: Hashable {
    enum Kind: Hashable {
        case warmup
        case work(setIndex: Int)
        case rest(setIndex: Int)
        case freeRun
        case cooldown
    }

    case warmup(target: BlockTarget)
    case work(setIndex: Int, target: BlockTarget)
    case rest(setIndex: Int, target: BlockTarget)
    case freeRun(goal: SessionGoal)
    case cooldown(target: BlockTarget)
}

extension RunPhase {
    var kind: Kind {
        switch self {
        case .warmup:
            return .warmup
        case .work(let setIndex, _):
            return .work(setIndex: setIndex)
        case .rest(let setIndex, _):
            return .rest(setIndex: setIndex)
        case .freeRun:
            return .freeRun
        case .cooldown:
            return .cooldown
        }
    }

    /// Whether this phase is complete given progress made so far. `.freeRun` with a `.free`
    /// goal never auto-completes — it only ends via a manual finish.
    func isComplete(elapsed: TimeInterval, phaseDistanceMeters: Double, sessionDistanceMeters: Double) -> Bool {
        switch self {
        case .warmup(let target), .cooldown(let target), .work(_, let target), .rest(_, let target):
            return target.isSatisfied(elapsed: elapsed, distanceMeters: phaseDistanceMeters)
        case .freeRun(let goal):
            switch goal {
            case .time(let seconds):
                return elapsed >= seconds
            case .distance(let meters, let scope):
                let distance = scope == .runOnly ? phaseDistanceMeters : sessionDistanceMeters
                return distance >= meters
            case .free:
                return false
            }
        }
    }
}

extension BlockTarget {
    func isSatisfied(elapsed: TimeInterval, distanceMeters: Double) -> Bool {
        switch self {
        case .duration(let seconds):
            return elapsed >= seconds
        case .distance(let meters):
            return distanceMeters >= meters
        }
    }
}

extension SessionPlan {
    /// Fixed sequence of phases this plan runs through:
    /// - `hiit` present: warmup, then `sets` work/rest pairs, then cooldown. `goal` is
    ///   informational only in this case — it doesn't gate any phase transition.
    /// - `hiit` nil: warmup, then a single `.freeRun(goal:)` phase, then cooldown.
    var runPhases: [RunPhase] {
        var phases: [RunPhase] = []
        if let warmup {
            phases.append(.warmup(target: warmup))
        }
        if let hiit {
            for setIndex in 0..<hiit.sets {
                phases.append(.work(setIndex: setIndex, target: hiit.work))
                phases.append(.rest(setIndex: setIndex, target: hiit.rest))
            }
        } else {
            phases.append(.freeRun(goal: goal))
        }
        if let cooldown {
            phases.append(.cooldown(target: cooldown))
        }
        return phases
    }
}
