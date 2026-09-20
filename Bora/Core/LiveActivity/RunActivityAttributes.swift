import ActivityKit
import Foundation

/// Live Activity payload for a run in progress. Compiled into both the app and the widget
/// extension, so it stays free of anything app-only.
nonisolated struct RunActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let phaseTitle: String
        let phaseNumber: Int
        let phaseCount: Int
        /// Anchor for the widget's self-updating timer, already shifted to discount paused
        /// time. The system renders the count from it without waking the app.
        let phaseStartedAt: Date
        /// `nil` when the block is gated by distance or the goal is open-ended — there is
        /// nothing to count down to, so the widget counts up instead.
        let phaseEndsAt: Date?
        /// When set, the timer freezes at this instant.
        let pausedAt: Date?
        let distanceMeters: Double
        let paceSecondsPerKm: Double?
        let upcomingPhaseTitle: String?
    }

    let planTitle: String
}
