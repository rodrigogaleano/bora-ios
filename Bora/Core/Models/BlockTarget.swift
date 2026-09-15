import Foundation

enum BlockTarget: Hashable {
    case duration(TimeInterval)
    case distance(meters: Double)
}

extension BlockTarget {
    var isValid: Bool {
        switch self {
        case .duration(let seconds):
            return seconds > 0
        case .distance(let meters):
            return meters > 0
        }
    }
}
