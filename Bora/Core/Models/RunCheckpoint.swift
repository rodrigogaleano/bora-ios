import Foundation

enum ProgressCheckpoint: Int, CaseIterable, Codable, Hashable {
    case quarter = 25
    case half = 50
    case threeQuarters = 75
    case ninety = 90

    var fraction: Double {
        Double(rawValue) / 100
    }
}

enum FinalStretch: Hashable {
    case lastKilometer
    case last100Meters
    case lastMinute
}
