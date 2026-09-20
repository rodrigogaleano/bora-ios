import Foundation

extension GPSAccuracy {
    var displayName: String {
        switch self {
        case .high:
            return String(localized: "High")
        case .balanced:
            return String(localized: "Balanced")
        case .economy:
            return String(localized: "Battery saver")
        }
    }
}
