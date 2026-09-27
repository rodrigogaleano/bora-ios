import Foundation

struct PhasePacer {
    static let minimumDistanceMeters: Double = 100

    private var kilometerMark: (elapsed: TimeInterval, distance: Double) = (0, 0)

    static func pace(seconds: TimeInterval, meters: Double, isSignalLost: Bool) -> Double? {
        guard !isSignalLost, meters >= minimumDistanceMeters else { return nil }
        return seconds / (meters / 1000)
    }

    static func recap(for phase: RunPhase, elapsed: TimeInterval, meters: Double, isSignalLost: Bool) -> RepRecap? {
        guard case .work(_, let target) = phase else { return nil }
        let measure: RepRecap.Measure
        switch target {
        case .distance:
            measure = .time(elapsed)
        case .duration:
            measure = .distance(meters: meters)
        }
        return RepRecap(
            measure: measure,
            paceSecondsPerKm: pace(seconds: elapsed, meters: meters, isSignalLost: isSignalLost)
        )
    }

    mutating func pacing(_ cue: RunCue, elapsed: TimeInterval, meters: Double, isSignalLost: Bool) -> RunCue {
        switch cue {
        case .progress(let checkpoint, _):
            return .progress(checkpoint, pace: Self.pace(seconds: elapsed, meters: meters, isSignalLost: isSignalLost))
        case .kilometerSplit(let kilometers, _):
            let pace = Self.pace(
                seconds: elapsed - kilometerMark.elapsed,
                meters: meters - kilometerMark.distance,
                isSignalLost: isSignalLost
            )
            kilometerMark = (elapsed, meters)
            return .kilometerSplit(kilometers, pace: pace)
        default:
            return cue
        }
    }
}
