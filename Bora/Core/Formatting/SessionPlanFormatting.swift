import Foundation

enum SessionPlanFormatting {
    /// One-line name of a plan, shared by the Summary screen and the Live Activity.
    static func title(for plan: SessionPlan) -> String {
        let hasIntervals = plan.hiit != nil
        switch plan.goal {
        case .distance(let meters, _):
            let distance = RunFormatting.distance(meters: meters)
            return hasIntervals
                ? String(localized: "\(distance) with intervals")
                : String(localized: "\(distance) continuous")
        case .time(let seconds):
            let duration = RunFormatting.compactDuration(seconds)
            return hasIntervals
                ? String(localized: "\(duration) with intervals")
                : String(localized: "\(duration) continuous")
        case .free:
            return String(localized: "Free session")
        }
    }
}
