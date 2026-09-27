import Foundation

struct RepRecap: Hashable {
    enum Measure: Hashable {
        case time(TimeInterval)
        case distance(meters: Double)
    }

    var measure: Measure
    var paceSecondsPerKm: Double?
}

struct FinalPace: Hashable {
    var secondsPerKm: Double
    var isRepsOnly: Bool
}
