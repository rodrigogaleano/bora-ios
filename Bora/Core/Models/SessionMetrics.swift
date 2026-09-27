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

    var startedAt: Date
    var endedAt: Date?
    var totalDistanceMeters: Double = 0
    var totalDuration: TimeInterval = 0
    var averagePaceSecondsPerKm: Double?
    var maxSpeedMetersPerSecond: Double?
    var splits: [BlockSplit] = []
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

    var isIntervalSession: Bool {
        splits.contains { split in
            if case .work = split.phase {
                return true
            }
            return false
        }
    }
}
