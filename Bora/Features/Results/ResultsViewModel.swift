import Foundation

@Observable
final class ResultsViewModel {
    struct SplitRow: Identifiable {
        let id: Int
        let title: String
        let distance: String
        let duration: String
        let pace: String
    }

    let metrics: SessionMetrics
    private let onDone: () -> Void

    init(metrics: SessionMetrics, onDone: @escaping () -> Void) {
        self.metrics = metrics
        self.onDone = onDone
    }

    var totalDistance: String {
        RunFormatting.distance(meters: metrics.totalDistanceMeters)
    }

    var totalDuration: String {
        RunFormatting.duration(metrics.totalDuration)
    }

    var averagePace: String {
        RunFormatting.pace(secondsPerKm: metrics.averagePaceSecondsPerKm)
    }

    var bestPace: String {
        RunFormatting.pace(speedMetersPerSecond: metrics.maxSpeedMetersPerSecond)
    }

    var splitRows: [SplitRow] {
        metrics.splits.enumerated().map { index, split in
            SplitRow(
                id: index,
                title: split.phase.displayName,
                distance: RunFormatting.distance(meters: split.distanceMeters),
                duration: RunFormatting.duration(split.endedAt.timeIntervalSince(split.startedAt)),
                pace: RunFormatting.pace(secondsPerKm: split.averagePaceSecondsPerKm)
            )
        }
    }

    func done() {
        onDone()
    }
}
