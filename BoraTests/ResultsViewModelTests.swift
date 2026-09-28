import Foundation
import Testing
@testable import Bora

struct ResultsViewModelTests {
    private let referenceDate = Date(timeIntervalSince1970: 0)

    private func makeSplit(
        phase: RunPhase.Kind,
        seconds: TimeInterval,
        distanceMeters: Double,
        paceSecondsPerKm: Double?
    ) -> SessionMetrics.BlockSplit {
        SessionMetrics.BlockSplit(
            phase: phase,
            startedAt: referenceDate,
            endedAt: referenceDate.addingTimeInterval(seconds),
            duration: seconds,
            distanceMeters: distanceMeters,
            averagePaceSecondsPerKm: paceSecondsPerKm
        )
    }

    private func makeViewModel(
        metrics: SessionMetrics,
        onDone: @escaping () -> Void = {}
    ) -> ResultsViewModel {
        ResultsViewModel(
            plan: SessionPlan(goal: .free),
            metrics: metrics,
            snapshotter: PreviewRouteSnapshotter(),
            onDone: onDone
        )
    }

    @Test func splitRowsPreserveOrderAndCountWithUniqueIdentifiers() {
        let metrics = SessionMetrics(
            startedAt: referenceDate,
            splits: [
                makeSplit(phase: .warmup, seconds: 60, distanceMeters: 200, paceSecondsPerKm: 300),
                makeSplit(phase: .work(setIndex: 0), seconds: 30, distanceMeters: 150, paceSecondsPerKm: 200),
                makeSplit(phase: .rest(setIndex: 0), seconds: 30, distanceMeters: 50, paceSecondsPerKm: 600)
            ]
        )
        let rows = makeViewModel(metrics: metrics).splitRows

        #expect(rows.count == 3)
        #expect(rows.map(\.title) == ["Warmup", "Work 1", "Rest 1"])
        #expect(Set(rows.map(\.id)).count == 3)
    }

    @Test func splitWithoutDistanceShowsPlaceholderPace() {
        let metrics = SessionMetrics(
            startedAt: referenceDate,
            splits: [makeSplit(phase: .cooldown, seconds: 45, distanceMeters: 0, paceSecondsPerKm: nil)]
        )
        let row = makeViewModel(metrics: metrics).splitRows[0]

        #expect(row.pace == RunFormatting.placeholder)
        #expect(row.duration == "00:45")
    }

    @Test func missingAveragePaceShowsPlaceholder() {
        let metrics = SessionMetrics(startedAt: referenceDate, averagePaceSecondsPerKm: nil)

        #expect(makeViewModel(metrics: metrics).averagePace == RunFormatting.placeholder)
    }

    @Test func averagePaceLeavesOutWarmupAndRest() {
        let metrics = SessionMetrics(
            startedAt: referenceDate,
            averagePaceSecondsPerKm: 400,
            splits: [
                makeSplit(phase: .warmup, seconds: 600, distanceMeters: 1_500, paceSecondsPerKm: 400),
                makeSplit(phase: .freeRun, seconds: 1_500, distanceMeters: 5_000, paceSecondsPerKm: 300)
            ]
        )
        let viewModel = makeViewModel(metrics: metrics)

        #expect(viewModel.averagePace == "05:00 /km")
        #expect(String(localized: viewModel.averagePaceTitle) == "Avg pace")
    }

    @Test func intervalSessionShowsWorkPace() {
        let metrics = SessionMetrics(
            startedAt: referenceDate,
            splits: [
                makeSplit(phase: .work(setIndex: 0), seconds: 90, distanceMeters: 400, paceSecondsPerKm: 225),
                makeSplit(phase: .rest(setIndex: 0), seconds: 90, distanceMeters: 150, paceSecondsPerKm: 600)
            ]
        )

        #expect(String(localized: makeViewModel(metrics: metrics).averagePaceTitle) == "Work pace")
    }

    @Test func durationFormatsWithHoursOnlyWhenPastOneHour() {
        let underAnHour = SessionMetrics(startedAt: referenceDate, totalDuration: 3599)
        let overAnHour = SessionMetrics(startedAt: referenceDate, totalDuration: 3930)

        #expect(makeViewModel(metrics: underAnHour).totalDuration == "59:59")
        #expect(makeViewModel(metrics: overAnHour).totalDuration == "1:05:30")
    }

    @Test func bestPaceDerivesFromMaxSpeed() {
        let metrics = SessionMetrics(startedAt: referenceDate, maxSpeedMetersPerSecond: 4)

        // 4 m/s is 250 s/km.
        #expect(makeViewModel(metrics: metrics).bestPace == "04:10 /km")
    }

    @Test func bestPaceWithoutMaxSpeedShowsPlaceholder() {
        let metrics = SessionMetrics(startedAt: referenceDate, maxSpeedMetersPerSecond: 0)

        #expect(makeViewModel(metrics: metrics).bestPace == RunFormatting.placeholder)
    }

    @Test func doneInvokesCallback() {
        var didFinish = false
        let viewModel = makeViewModel(
            metrics: SessionMetrics(startedAt: referenceDate),
            onDone: { didFinish = true }
        )

        viewModel.done()

        #expect(didFinish)
    }
}
