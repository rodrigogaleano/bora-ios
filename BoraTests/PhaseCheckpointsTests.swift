import Testing
@testable import Bora

struct PhaseCheckpointsTests {
    private func progress(
        elapsed: Double = 0,
        phaseDistance: Double = 0,
        sessionDistance: Double = 0
    ) -> PhaseCheckpoints.Progress {
        PhaseCheckpoints.Progress(
            elapsed: elapsed,
            phaseDistanceMeters: phaseDistance,
            sessionDistanceMeters: sessionDistance
        )
    }

    @Test func timedBlockWarnsTenSecondsBeforeItEnds() {
        var checkpoints = PhaseCheckpoints(
            phase: .warmup(target: .duration(60)),
            nextPhase: .freeRun(goal: .free),
            config: CheckpointConfig()
        )

        #expect(checkpoints.cue(for: progress(elapsed: 49)) == nil)
        #expect(checkpoints.cue(for: progress(elapsed: 50)) == .upcomingTransition("Run"))
    }

    @Test func distanceBlockWarnsFiftyMetersBeforeItEnds() {
        var checkpoints = PhaseCheckpoints(
            phase: .work(setIndex: 0, target: .distance(meters: 1_000)),
            nextPhase: .rest(setIndex: 0, target: .duration(90)),
            config: CheckpointConfig()
        )

        #expect(checkpoints.cue(for: progress(phaseDistance: 940)) == nil)
        #expect(checkpoints.cue(for: progress(phaseDistance: 955)) == .upcomingTransition("Rest 1"))
    }

    @Test func warningFiresOnlyOnce() {
        var checkpoints = PhaseCheckpoints(
            phase: .work(setIndex: 0, target: .distance(meters: 400)),
            nextPhase: .rest(setIndex: 0, target: .duration(60)),
            config: CheckpointConfig()
        )

        #expect(checkpoints.cue(for: progress(phaseDistance: 360)) != nil)
        #expect(checkpoints.cue(for: progress(phaseDistance: 380)) == nil)
    }

    @Test func lastBlockAnnouncesTheRunIsEnding() {
        var checkpoints = PhaseCheckpoints(
            phase: .cooldown(target: .duration(300)),
            nextPhase: nil,
            config: CheckpointConfig()
        )

        #expect(checkpoints.cue(for: progress(elapsed: 290)) == .runEnding)
    }

    @Test func sessionScopedDistanceGoalCountsTheWholeSession() {
        var checkpoints = PhaseCheckpoints(
            phase: .freeRun(goal: .distance(meters: 5_000, scope: .totalSession)),
            nextPhase: nil,
            config: CheckpointConfig()
        )

        #expect(checkpoints.cue(for: progress(phaseDistance: 4_000, sessionDistance: 4_900)) == nil)
        #expect(checkpoints.cue(for: progress(phaseDistance: 4_000, sessionDistance: 4_960)) == .runEnding)
    }

    @Test func freeGoalHasNothingToWarnAbout() {
        var checkpoints = PhaseCheckpoints(
            phase: .freeRun(goal: .free),
            nextPhase: nil,
            config: CheckpointConfig()
        )

        #expect(checkpoints.cue(for: progress(elapsed: 10_000, phaseDistance: 50_000)) == nil)
    }

    @Test func disabledWarningStaysSilent() {
        var checkpoints = PhaseCheckpoints(
            phase: .work(setIndex: 0, target: .distance(meters: 1_000)),
            nextPhase: .rest(setIndex: 0, target: .duration(90)),
            config: CheckpointConfig(isTransitionWarningEnabled: false)
        )

        #expect(checkpoints.cue(for: progress(phaseDistance: 990)) == nil)
    }
}
