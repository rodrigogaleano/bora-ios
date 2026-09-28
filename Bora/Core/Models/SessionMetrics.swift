import Foundation

struct SessionMetrics: Hashable {
    struct BlockSplit: Hashable {
        var phase: RunPhase.Kind
        var startedAt: Date
        var endedAt: Date
        var duration: TimeInterval
        var distanceMeters: Double
        var averagePaceSecondsPerKm: Double?
    }

    struct KilometerSplit: Hashable {
        var distanceMeters: Double
        var duration: TimeInterval
    }

    var startedAt: Date
    var endedAt: Date?
    var totalDistanceMeters: Double = 0
    var totalDuration: TimeInterval = 0
    var averagePaceSecondsPerKm: Double?
    var maxSpeedMetersPerSecond: Double?
    var splits: [BlockSplit] = []
    var kilometerSplits: [KilometerSplit] = []
    var route: [RouteCoordinate] = []
    var perceivedExertion: Int?
    var averageHeartRate: Double?
    var maxHeartRate: Double?
    var averageCadenceSPM: Double?
}

extension SessionMetrics {
    var effortPaceSecondsPerKm: Double? {
        let effort = splits.filter { $0.phase.isEffort }
        let distance = effort.reduce(0) { $0 + $1.distanceMeters }
        guard distance > 0 else { return nil }
        let duration = effort.reduce(0) { $0 + $1.duration }
        return duration / (distance / 1000)
    }

    var headlinePaceSecondsPerKm: Double? {
        effortPaceSecondsPerKm ?? averagePaceSecondsPerKm
    }

    var headlinePaceTitle: LocalizedStringResource {
        isIntervalSession ? "Work pace" : "Avg pace"
    }

    var isIntervalSession: Bool {
        splits.contains { split in
            if case .work = split.phase {
                return true
            }
            return false
        }
    }
}
