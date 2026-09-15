import Foundation

enum DistanceScope: Hashable {
    case totalSession
    case runOnly
}

enum SessionGoal: Hashable {
    case distance(meters: Double, scope: DistanceScope)
    case time(TimeInterval)
    case free
}

extension SessionGoal {
    var isValid: Bool {
        switch self {
        case .distance(let meters, _):
            return meters > 0
        case .time(let seconds):
            return seconds > 0
        case .free:
            return true
        }
    }
}
