import Foundation

enum RunFormatting {
    static let placeholder = "--:--"

    static func duration(_ interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Loose duration for planned blocks, where "30s" and "5 min" read better than a clock.
    static func compactDuration(_ interval: TimeInterval) -> String {
        let seconds = max(0, interval.rounded())
        if seconds < 60 {
            return Measurement(value: seconds, unit: UnitDuration.seconds)
                .formatted(.measurement(width: .abbreviated))
        }
        return Measurement(value: (seconds / 60).rounded(), unit: UnitDuration.minutes)
            .formatted(.measurement(width: .abbreviated))
    }

    static func pace(secondsPerKm: Double?) -> String {
        guard let secondsPerKm, secondsPerKm.isFinite, secondsPerKm > 0 else { return placeholder }
        let totalSeconds = Int(secondsPerKm)
        return String(format: "%02d:%02d /km", totalSeconds / 60, totalSeconds % 60)
    }

    static func pace(speedMetersPerSecond: Double?) -> String {
        guard let speedMetersPerSecond, speedMetersPerSecond > 0 else { return placeholder }
        return pace(secondsPerKm: 1000 / speedMetersPerSecond)
    }

    static func distance(meters: Double) -> String {
        Measurement(value: meters, unit: UnitLength.meters)
            .formatted(.measurement(width: .abbreviated, usage: .road))
    }
}

extension RunPhase.Kind {
    var displayName: String {
        switch self {
        case .warmup:
            return String(localized: "Warmup")
        case .work(let setIndex):
            return String(localized: "Work \(setIndex + 1)")
        case .rest(let setIndex):
            return String(localized: "Rest \(setIndex + 1)")
        case .freeRun:
            return String(localized: "Run")
        case .cooldown:
            return String(localized: "Cooldown")
        }
    }
}
