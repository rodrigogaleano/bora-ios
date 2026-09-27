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

    private struct Point {
        let axis: Axis
        let position: Double
        let cue: RunCue
    }

    private var pending: [Point]

    init(phase: RunPhase, nextPhase: RunPhase?, config: CheckpointConfig) {
        var points: [Point] = []
        if config.isTransitionWarningEnabled, let gate = phase.gate {
            let window = gate.axis == .elapsed ? Self.transitionWarningSeconds : Self.transitionWarningMeters
            let cue = nextPhase.map { RunCue.upcomingTransition($0.kind.displayName) } ?? .runEnding
            points.append(Point(axis: gate.axis, position: max(0, gate.end - window), cue: cue))
        }
        pending = points
    }

    mutating func cue(for progress: Progress) -> RunCue? {
        let isReached = { (point: Point) in progress.value(on: point.axis) >= point.position }
        guard let reached = pending.first(where: isReached) else { return nil }
        pending.removeAll(where: isReached)
        return reached.cue
    }
}

private extension RunPhase {
    var gate: (axis: PhaseCheckpoints.Axis, end: Double)? {
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
