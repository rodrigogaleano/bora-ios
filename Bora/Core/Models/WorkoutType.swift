import Foundation

enum WorkoutType: CaseIterable, Hashable {
    case easyRun
    case longRun
    case intervals
    case freeRun

    var title: String {
        switch self {
        case .easyRun:
            return String(localized: "Easy run")
        case .longRun:
            return String(localized: "Long run")
        case .intervals:
            return String(localized: "Intervals")
        case .freeRun:
            return String(localized: "Free run")
        }
    }

    var summary: String {
        switch self {
        case .easyRun:
            return String(localized: "Continuous run at an easy pace")
        case .longRun:
            return String(localized: "Your longest run of the week")
        case .intervals:
            return String(localized: "Repeats, fartlek, hills or run/walk")
        case .freeRun:
            return String(localized: "No goal, just run")
        }
    }

    var systemImage: String {
        switch self {
        case .easyRun:
            return "figure.run"
        case .longRun:
            return "road.lanes"
        case .intervals:
            return "timer"
        case .freeRun:
            return "infinity"
        }
    }
}
