import Foundation
import Testing
@testable import Bora

struct SessionMetricsTests {
    private let referenceDate = Date(timeIntervalSince1970: 0)

    private func split(_ phase: RunPhase.Kind, seconds: TimeInterval, meters: Double) -> SessionMetrics.BlockSplit {
        SessionMetrics.BlockSplit(
            phase: phase,
            startedAt: referenceDate,
            endedAt: referenceDate.addingTimeInterval(seconds),
            duration: seconds,
            distanceMeters: meters,
            averagePaceSecondsPerKm: nil
        )
    }

    @Test func effortPaceLeavesOutWarmupRestAndCooldown() {
        let metrics = SessionMetrics(
            startedAt: referenceDate,
            splits: [
                split(.warmup, seconds: 600, meters: 1_500),
                split(.work(setIndex: 0), seconds: 90, meters: 400),
                split(.rest(setIndex: 0), seconds: 90, meters: 150),
                split(.work(setIndex: 1), seconds: 90, meters: 400),
                split(.cooldown, seconds: 600, meters: 1_500)
            ]
        )

        #expect(metrics.effortPaceSecondsPerKm == 225)
        #expect(metrics.isIntervalSession)
    }

    @Test func effortPaceWeighsLongerRepsMore() {
        let metrics = SessionMetrics(
            startedAt: referenceDate,
            splits: [
                split(.work(setIndex: 0), seconds: 200, meters: 1_000),
                split(.work(setIndex: 1), seconds: 100, meters: 400)
            ]
        )

        #expect(metrics.effortPaceSecondsPerKm == 300 / 1.4)
    }

    @Test func effortPaceNeedsDistance() {
        let metrics = SessionMetrics(
            startedAt: referenceDate,
            splits: [split(.freeRun, seconds: 600, meters: 0)]
        )

        #expect(metrics.effortPaceSecondsPerKm == nil)
        #expect(!metrics.isIntervalSession)
    }
}
