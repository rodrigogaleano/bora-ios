import Foundation

/// Snapshot of an in-flight run, as the Live Activity needs to see it.
struct RunActivityProgress {
    let phaseTitle: String
    let phaseNumber: Int
    let phaseCount: Int
    let elapsedInPhase: TimeInterval
    /// `nil` for a block gated by distance, or an open-ended goal.
    let remainingInPhase: TimeInterval?
    let pausedAt: Date?
    let distanceMeters: Double
    let speedMetersPerSecond: Double
    let upcomingPhaseTitle: String?
}

/// Turns run progress into a Live Activity state, and decides when a new state is worth
/// publishing. Pure on purpose: the throttle is what protects the battery, and it is the
/// part worth testing.
enum RunActivityStateBuilder {
    /// A run updates twice a second, but the widget only needs a new payload when a number
    /// the user reads actually moved. Timers render themselves from `phaseStartedAt`, so
    /// they never need one.
    static let minimumPublishInterval: TimeInterval = 5
    private static let distanceStepMeters: Double = 10
    private static let paceStepSecondsPerKm: Double = 5

    static func state(from progress: RunActivityProgress, now: Date) -> RunActivityAttributes.ContentState {
        let startedAt = now.addingTimeInterval(-max(0, progress.elapsedInPhase))
        let endsAt = progress.remainingInPhase.map { now.addingTimeInterval(max(0, $0)) }
        return RunActivityAttributes.ContentState(
            phaseTitle: progress.phaseTitle,
            phaseNumber: progress.phaseNumber,
            phaseCount: progress.phaseCount,
            phaseStartedAt: startedAt,
            phaseEndsAt: endsAt.map { max($0, startedAt) },
            pausedAt: progress.pausedAt,
            distanceMeters: progress.distanceMeters,
            paceSecondsPerKm: progress.speedMetersPerSecond > 0 ? 1000 / progress.speedMetersPerSecond : nil,
            upcomingPhaseTitle: progress.upcomingPhaseTitle
        )
    }

    /// Phase changes and pauses publish immediately — they are what the user glances at the
    /// lock screen for. Everything else waits out the interval and has to have moved.
    static func shouldPublish(
        previous: RunActivityAttributes.ContentState?,
        next: RunActivityAttributes.ContentState,
        secondsSinceLastPublish: TimeInterval
    ) -> Bool {
        guard let previous else { return true }
        if previous.phaseNumber != next.phaseNumber { return true }
        if previous.pausedAt != next.pausedAt { return true }
        if previous.upcomingPhaseTitle != next.upcomingPhaseTitle { return true }
        guard secondsSinceLastPublish >= minimumPublishInterval else { return false }
        if abs(previous.distanceMeters - next.distanceMeters) >= distanceStepMeters { return true }
        return hasMovedPace(from: previous.paceSecondsPerKm, to: next.paceSecondsPerKm)
    }

    private static func hasMovedPace(from previous: Double?, to next: Double?) -> Bool {
        switch (previous, next) {
        case (nil, nil):
            return false
        case (nil, .some), (.some, nil):
            return true
        case (.some(let previous), .some(let next)):
            return abs(previous - next) >= paceStepSecondsPerKm
        }
    }
}
