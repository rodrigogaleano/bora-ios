import Foundation

struct PhaseCheckpoints {
    static let transitionWarningSeconds: TimeInterval = 10
    static let transitionWarningMeters: Double = 50

    enum Axis: Hashable {
        case elapsed
        case phaseDistance
        case sessionDistance
    }

    struct Progress: Hashable {
        static let zero = Progress(elapsed: 0, phaseDistanceMeters: 0, sessionDistanceMeters: 0)

        var elapsed: TimeInterval
        var phaseDistanceMeters: Double
        var sessionDistanceMeters: Double

        func value(on axis: Axis) -> Double {
            switch axis {
            case .elapsed:
                return elapsed
            case .phaseDistance:
                return phaseDistanceMeters
            case .sessionDistance:
                return sessionDistanceMeters
            }
        }
    }

    fileprivate typealias Gate = (axis: Axis, end: Double)

    fileprivate enum Priority: Int, Comparable {
        case transition
        case finalStretch
        case progress
        case kilometer

        static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    fileprivate struct Point {
        let axis: Axis
        let position: Double
        let cue: RunCue
        let priority: Priority
    }

    private var pending: [Point]

    init(phase: RunPhase, nextPhase: RunPhase?, config: CheckpointConfig, startingAt start: Progress = .zero) {
        let gate = phase.gate
        var points: [Point] = []
        if config.isTransitionWarningEnabled, let gate {
            points += Self.transitionPoints(gate: gate, nextPhase: nextPhase)
        }
        if phase.kind.isEffort {
            if config.isFinalStretchEnabled, let gate {
                points += Self.finalStretchPoints(gate: gate)
            }
            if let gate {
                points += Self.progressPoints(gate: gate, checkpoints: config.progress)
            }
            if config.isKilometerSplitEnabled {
                points += Self.kilometerPoints(gate: gate)
            }
        }
        pending = Self.resolveCollisions(points.filter { $0.position >= start.value(on: $0.axis) })
    }

    mutating func cue(for progress: Progress) -> RunCue? {
        let isReached = { (point: Point) in progress.value(on: point.axis) >= point.position }
        guard let reached = pending.first(where: isReached) else { return nil }
        pending.removeAll(where: isReached)
        return reached.cue
    }
}

private extension PhaseCheckpoints {
    static let progressMinimumSeconds: TimeInterval = 240
    static let progressMinimumMeters: Double = 800
    static let kilometerSplitLimitMeters: Double = 100_000

    static func window(on axis: Axis) -> Double {
        axis == .elapsed ? transitionWarningSeconds : transitionWarningMeters
    }

    static func transitionPoints(gate: Gate, nextPhase: RunPhase?) -> [Point] {
        let cue = nextPhase.map { RunCue.upcomingTransition($0.kind.displayName) } ?? .runEnding
        let position = max(0, gate.end - window(on: gate.axis))
        return [Point(axis: gate.axis, position: position, cue: cue, priority: .transition)]
    }

    static func finalStretchPoints(gate: Gate) -> [Point] {
        let stretches: [FinalStretch] = gate.axis == .elapsed ? [.lastMinute] : [.lastKilometer, .last100Meters]
        return stretches
            .filter { gate.end >= $0.minimumGoal }
            .map { stretch in
                Point(
                    axis: gate.axis,
                    position: gate.end - stretch.remaining,
                    cue: .finalStretch(stretch),
                    priority: .finalStretch
                )
            }
    }

    static func progressPoints(gate: Gate, checkpoints: Set<ProgressCheckpoint>) -> [Point] {
        let minimum = gate.axis == .elapsed ? progressMinimumSeconds : progressMinimumMeters
        guard gate.end >= minimum else { return [] }
        return checkpoints
            .sorted { $0.rawValue < $1.rawValue }
            .map { checkpoint in
                Point(
                    axis: gate.axis,
                    position: gate.end * checkpoint.fraction,
                    cue: .progress(checkpoint),
                    priority: .progress
                )
            }
    }

    static func kilometerPoints(gate: Gate?) -> [Point] {
        let axis: Axis
        let limit: Double
        if let gate, gate.axis != .elapsed {
            axis = gate.axis
            limit = gate.end
        } else {
            axis = .phaseDistance
            limit = kilometerSplitLimitMeters
        }
        return stride(from: 1_000.0, to: limit, by: 1_000).map { meters in
            Point(axis: axis, position: meters, cue: .kilometerSplit(Int(meters / 1_000)), priority: .kilometer)
        }
    }

    static func resolveCollisions(_ points: [Point]) -> [Point] {
        points
            .sorted { ($0.priority, -$0.position) < ($1.priority, -$1.position) }
            .reduce(into: []) { kept, point in
                let collides = kept.contains { other in
                    other.axis == point.axis && abs(other.position - point.position) < window(on: point.axis)
                }
                if !collides {
                    kept.append(point)
                }
            }
    }
}

private extension FinalStretch {
    var minimumGoal: Double {
        switch self {
        case .lastKilometer:
            return 2_500
        case .last100Meters:
            return 500
        case .lastMinute:
            return 180
        }
    }

    var remaining: Double {
        switch self {
        case .lastKilometer:
            return 1_000
        case .last100Meters:
            return 100
        case .lastMinute:
            return 60
        }
    }
}

private extension RunPhase {
    var gate: PhaseCheckpoints.Gate? {
        switch self {
        case .warmup(let target), .cooldown(let target), .work(_, let target), .rest(_, let target):
            switch target {
            case .duration(let seconds):
                return (.elapsed, seconds)
            case .distance(let meters):
                return (.phaseDistance, meters)
            }
        case .freeRun(let goal):
            switch goal {
            case .time(let seconds):
                return (.elapsed, seconds)
            case .distance(let meters, let scope):
                return (scope == .runOnly ? .phaseDistance : .sessionDistance, meters)
            case .free:
                return nil
            }
        }
    }
}
