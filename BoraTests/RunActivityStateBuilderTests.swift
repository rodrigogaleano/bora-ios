import Foundation
import Testing
@testable import Bora

struct RunActivityStateBuilderTests {
    private let now = Date(timeIntervalSince1970: 1_000_000)

    private func makeProgress(
        elapsedInPhase: TimeInterval = 0,
        remainingInPhase: TimeInterval? = nil,
        pausedAt: Date? = nil,
        distanceMeters: Double = 0,
        speedMetersPerSecond: Double = 0
    ) -> RunActivityProgress {
        RunActivityProgress(
            phaseTitle: "Warmup",
            phaseNumber: 1,
            phaseCount: 3,
            elapsedInPhase: elapsedInPhase,
            remainingInPhase: remainingInPhase,
            pausedAt: pausedAt,
            distanceMeters: distanceMeters,
            speedMetersPerSecond: speedMetersPerSecond,
            upcomingPhaseTitle: nil
        )
    }

    @Test func phaseStartAnchorDiscountsTimeAlreadyElapsed() {
        let state = RunActivityStateBuilder.state(from: makeProgress(elapsedInPhase: 90), now: now)
        #expect(state.phaseStartedAt == now.addingTimeInterval(-90))
    }

    @Test func phaseEndIsProjectedFromTheRemainingTime() {
        let progress = makeProgress(elapsedInPhase: 30, remainingInPhase: 60)
        let state = RunActivityStateBuilder.state(from: progress, now: now)
        #expect(state.phaseEndsAt == now.addingTimeInterval(60))
    }

    /// Distance-gated blocks and open-ended goals have nothing to count down to.
    @Test func phaseEndIsAbsentWithoutARemainingTime() {
        let state = RunActivityStateBuilder.state(from: makeProgress(elapsedInPhase: 30), now: now)
        #expect(state.phaseEndsAt == nil)
    }

    @Test func paceIsDerivedFromSpeedAndAbsentWhenStopped() {
        let moving = RunActivityStateBuilder.state(from: makeProgress(speedMetersPerSecond: 4), now: now)
        #expect(moving.paceSecondsPerKm == 250)

        let stopped = RunActivityStateBuilder.state(from: makeProgress(speedMetersPerSecond: 0), now: now)
        #expect(stopped.paceSecondsPerKm == nil)
    }

    @Test func firstStateAlwaysPublishes() {
        let state = RunActivityStateBuilder.state(from: makeProgress(), now: now)
        #expect(RunActivityStateBuilder.shouldPublish(previous: nil, next: state, secondsSinceLastPublish: 0))
    }

    @Test func phaseChangePublishesRightAway() {
        let previous = RunActivityStateBuilder.state(from: makeProgress(), now: now)
        let progress = RunActivityProgress(
            phaseTitle: "Run",
            phaseNumber: 2,
            phaseCount: 3,
            elapsedInPhase: 0,
            remainingInPhase: nil,
            pausedAt: nil,
            distanceMeters: 0,
            speedMetersPerSecond: 0,
            upcomingPhaseTitle: nil
        )
        let next = RunActivityStateBuilder.state(from: progress, now: now)
        #expect(RunActivityStateBuilder.shouldPublish(previous: previous, next: next, secondsSinceLastPublish: 0))
    }

    @Test func pauseAndResumePublishRightAway() {
        let running = RunActivityStateBuilder.state(from: makeProgress(), now: now)
        let paused = RunActivityStateBuilder.state(from: makeProgress(pausedAt: now), now: now)
        #expect(RunActivityStateBuilder.shouldPublish(previous: running, next: paused, secondsSinceLastPublish: 0))
        #expect(RunActivityStateBuilder.shouldPublish(previous: paused, next: running, secondsSinceLastPublish: 0))
    }

    @Test func movementIsHeldUntilTheIntervalPasses() {
        let previous = RunActivityStateBuilder.state(from: makeProgress(distanceMeters: 100), now: now)
        let next = RunActivityStateBuilder.state(from: makeProgress(distanceMeters: 400), now: now)
        #expect(!RunActivityStateBuilder.shouldPublish(previous: previous, next: next, secondsSinceLastPublish: 4))
        #expect(RunActivityStateBuilder.shouldPublish(previous: previous, next: next, secondsSinceLastPublish: 5))
    }

    @Test func aStandingRunnerDoesNotPublish() {
        let previous = RunActivityStateBuilder.state(from: makeProgress(distanceMeters: 100), now: now)
        let next = RunActivityStateBuilder.state(from: makeProgress(distanceMeters: 105), now: now)
        #expect(!RunActivityStateBuilder.shouldPublish(previous: previous, next: next, secondsSinceLastPublish: 60))
    }

    @Test func paceAloneCanTriggerAPublish() {
        let previous = RunActivityStateBuilder.state(
            from: makeProgress(distanceMeters: 100, speedMetersPerSecond: 4),
            now: now
        )
        let next = RunActivityStateBuilder.state(
            from: makeProgress(distanceMeters: 105, speedMetersPerSecond: 3),
            now: now
        )
        #expect(RunActivityStateBuilder.shouldPublish(previous: previous, next: next, secondsSinceLastPublish: 5))
    }
}
