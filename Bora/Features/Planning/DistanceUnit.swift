import Foundation

enum DistanceUnit: CaseIterable, Hashable {
    case meters
    case kilometers

    var metersPerUnit: Double {
        switch self {
        case .meters:
            return 1
        case .kilometers:
            return 1_000
        }
    }

    var symbol: String {
        switch self {
        case .meters:
            return UnitLength.meters.symbol
        case .kilometers:
            return UnitLength.kilometers.symbol
        }
    }

    func value(fromMeters meters: Double) -> Double {
        meters / metersPerUnit
    }

    func meters(from value: Double) -> Double {
        value * metersPerUnit
    }
}
