import Foundation

struct SessionMetrics: Hashable {
    struct BlockSplit: Hashable {
        var phase: RunPhase.Kind
        var startedAt: Date
        var endedAt: Date
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
