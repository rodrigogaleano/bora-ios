import CoreLocation

/// Precision-versus-battery profile for tracking a run. One level drives both what we ask
/// the hardware for and how strict we are about the fixes it hands back.
enum GPSAccuracy: String, Codable, CaseIterable, Hashable {
    case high
    case balanced
    case economy

    /// No human covers ground faster than this, so a fix implying it is a GPS jump. Fixed
    /// across levels — it filters teleports, not noise.
    static let maximumSpeedMetersPerSecond: Double = 12

    /// Fixes whose reported uncertainty is worse than this are discarded.
    var maximumHorizontalAccuracy: Double {
        switch self {
        case .high: 10
        case .balanced: 20
        case .economy: 50
        }
    }

    var desiredAccuracy: CLLocationAccuracy {
        switch self {
        case .high: kCLLocationAccuracyBest
        case .balanced: kCLLocationAccuracyNearestTenMeters
        case .economy: kCLLocationAccuracyHundredMeters
        }
    }
}
