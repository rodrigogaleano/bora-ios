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

    let plan: SessionPlan
    let metrics: SessionMetrics
    private let snapshotter: RouteSnapshotProviding
    private let onDone: () -> Void
    var isSharePresented = false

    init(
        plan: SessionPlan,
        metrics: SessionMetrics,
        snapshotter: RouteSnapshotProviding,
        onDone: @escaping () -> Void
    ) {
        self.plan = plan
        self.metrics = metrics
        self.snapshotter = snapshotter
        self.onDone = onDone
    }

    var totalDistance: String {
        RunFormatting.distance(meters: metrics.totalDistanceMeters)
    }

    var totalDuration: String {
        RunFormatting.duration(metrics.totalDuration)
    }

    var averagePace: String {
        RunFormatting.pace(secondsPerKm: metrics.headlinePaceSecondsPerKm)
    }

    var averagePaceTitle: LocalizedStringResource {
        metrics.headlinePaceTitle
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
                duration: RunFormatting.duration(split.duration),
                pace: RunFormatting.pace(secondsPerKm: split.averagePaceSecondsPerKm)
            )
        }
    }

    func share() {
        isSharePresented = true
    }

    func makeShareViewModel() -> ShareViewModel {
        ShareViewModel(plan: plan, metrics: metrics, snapshotter: snapshotter)
    }

    func done() {
        onDone()
    }
}
