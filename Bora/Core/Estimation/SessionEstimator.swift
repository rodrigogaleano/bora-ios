import Foundation

struct EstimatedBlock: Equatable {
    let kind: RunPhase.Kind
    let duration: TimeInterval
    let distanceMeters: Double
}

struct SessionEstimate: Equatable {
    let blocks: [EstimatedBlock]
    let duration: TimeInterval
    let totalDistanceMeters: Double
    /// Distance covered in the blocks that count as running — work sets and the free run.
    let runDistanceMeters: Double
    /// A `.free` goal without HIIT has no end condition, so nothing here can be estimated.
    let isOpenEnded: Bool
}

/// Turns a plan into the numbers the summary screen shows before the run starts.
///
/// Every block is either a duration or a distance, so the missing half is derived from an
/// assumed pace. The MVP has no pace history to derive those from — the table below is a
/// fixed assumption, and the screen labels everything it produces as an estimate.
enum SessionEstimator {
    /// Assumed pace per block kind, in seconds per kilometre.
    static func paceSecondsPerKm(for kind: RunPhase.Kind) -> Double {
        switch kind {
        case .warmup: return 390
        case .work: return 258
        case .rest: return 430
        case .cooldown: return 405
        case .freeRun: return 335
        }
    }

    /// Floors for a free run whose goal is mostly eaten by warmup and cooldown, so the plan
    /// still shows a run block instead of nothing.
    private static let minimumFreeRunDistanceMeters: Double = 400
    private static let minimumFreeRunDuration: TimeInterval = 300

    static func estimate(for plan: SessionPlan) -> SessionEstimate {
        let bookends = bookends(for: plan)
        var blocks: [EstimatedBlock] = []
        var isOpenEnded = false

        for phase in plan.runPhases {
            switch phase {
            case .warmup(let target), .cooldown(let target), .work(_, let target), .rest(_, let target):
                blocks.append(block(kind: phase.kind, target: target))
            case .freeRun(let goal):
                guard let target = freeRunTarget(goal: goal, bookends: bookends) else {
                    isOpenEnded = true
                    blocks.append(EstimatedBlock(kind: .freeRun, duration: 0, distanceMeters: 0))
                    continue
                }
                blocks.append(block(kind: .freeRun, target: target))
            }
        }

        return SessionEstimate(
            blocks: blocks,
            duration: blocks.reduce(0) { $0 + $1.duration },
            totalDistanceMeters: blocks.reduce(0) { $0 + $1.distanceMeters },
            runDistanceMeters: blocks.reduce(0) { total, block in
                switch block.kind {
                case .work, .freeRun: return total + block.distanceMeters
                case .warmup, .rest, .cooldown: return total
                }
            },
            isOpenEnded: isOpenEnded
        )
    }

    private static func block(kind: RunPhase.Kind, target: BlockTarget) -> EstimatedBlock {
        let pace = paceSecondsPerKm(for: kind)
        switch target {
        case .duration(let seconds):
            return EstimatedBlock(kind: kind, duration: seconds, distanceMeters: seconds / pace * 1000)
        case .distance(let meters):
            return EstimatedBlock(kind: kind, duration: meters / 1000 * pace, distanceMeters: meters)
        }
    }

    /// Warmup and cooldown together — a goal counted over the whole session has to fit inside
    /// what's left after them.
    private static func bookends(for plan: SessionPlan) -> EstimatedBlock {
        let warmup = plan.warmup.map { block(kind: .warmup, target: $0) }
        let cooldown = plan.cooldown.map { block(kind: .cooldown, target: $0) }
        return EstimatedBlock(
            kind: .freeRun,
            duration: (warmup?.duration ?? 0) + (cooldown?.duration ?? 0),
            distanceMeters: (warmup?.distanceMeters ?? 0) + (cooldown?.distanceMeters ?? 0)
        )
    }

    private static func freeRunTarget(goal: SessionGoal, bookends: EstimatedBlock) -> BlockTarget? {
        switch goal {
        case .distance(let meters, let scope):
            guard scope == .totalSession else { return .distance(meters: meters) }
            return .distance(meters: max(minimumFreeRunDistanceMeters, meters - bookends.distanceMeters))
        case .time(let seconds):
            return .duration(max(minimumFreeRunDuration, seconds - bookends.duration))
        case .free:
            return nil
        }
    }
}
