import Testing
@testable import Bora

struct PhaseCheckpointsTests {
    private let transitionOnly = CheckpointConfig(progress: [], isFinalStretchEnabled: false)

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
            config: transitionOnly
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
            config: transitionOnly
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
            config: CheckpointConfig(isTransitionWarningEnabled: false, progress: [], isFinalStretchEnabled: false)
        )

        #expect(checkpoints.cue(for: progress(phaseDistance: 990)) == nil)
    }

    @Test func kilometerWorkBlockPlaysHalfwayFinalStretchAndTransition() {
        var checkpoints = PhaseCheckpoints(
            phase: .work(setIndex: 0, target: .distance(meters: 1_000)),
            nextPhase: .rest(setIndex: 0, target: .duration(90)),
            config: CheckpointConfig(progress: [.half, .ninety])
        )

        #expect(checkpoints.cue(for: progress(phaseDistance: 499)) == nil)
        #expect(checkpoints.cue(for: progress(phaseDistance: 500)) == .progress(.half))
        #expect(checkpoints.cue(for: progress(phaseDistance: 900)) == .finalStretch(.last100Meters))
        #expect(checkpoints.cue(for: progress(phaseDistance: 949)) == nil)
        #expect(checkpoints.cue(for: progress(phaseDistance: 950)) == .upcomingTransition("Rest 1"))
    }

    @Test func shortBlocksSkipProgressAndFinalStretch() {
        var checkpoints = PhaseCheckpoints(
            phase: .work(setIndex: 0, target: .distance(meters: 400)),
            nextPhase: .rest(setIndex: 0, target: .duration(60)),
            config: CheckpointConfig()
        )

        #expect(checkpoints.cue(for: progress(phaseDistance: 349)) == nil)
        #expect(checkpoints.cue(for: progress(phaseDistance: 350)) == .upcomingTransition("Rest 1"))
    }

    @Test func last100MetersStartsAtHalfAKilometer() {
        var checkpoints = PhaseCheckpoints(
            phase: .work(setIndex: 0, target: .distance(meters: 500)),
            nextPhase: .rest(setIndex: 0, target: .duration(60)),
            config: CheckpointConfig()
        )

        #expect(checkpoints.cue(for: progress(phaseDistance: 400)) == .finalStretch(.last100Meters))
    }

    @Test func lastKilometerNeedsTwoAndAHalfKilometers() {
        var twoKilometers = PhaseCheckpoints(
            phase: .work(setIndex: 0, target: .distance(meters: 2_000)),
            nextPhase: nil,
            config: CheckpointConfig(progress: [])
        )
        var threeKilometers = PhaseCheckpoints(
            phase: .work(setIndex: 0, target: .distance(meters: 3_000)),
            nextPhase: nil,
            config: CheckpointConfig(progress: [])
        )

        #expect(twoKilometers.cue(for: progress(phaseDistance: 1_000)) == nil)
        #expect(threeKilometers.cue(for: progress(phaseDistance: 2_000)) == .finalStretch(.lastKilometer))
    }

    @Test func recoveryBlocksOnlyWarnAboutTheTransition() {
        var checkpoints = PhaseCheckpoints(
            phase: .rest(setIndex: 0, target: .distance(meters: 1_000)),
            nextPhase: .work(setIndex: 1, target: .distance(meters: 1_000)),
            config: CheckpointConfig(isKilometerSplitEnabled: true)
        )

        #expect(checkpoints.cue(for: progress(phaseDistance: 900)) == nil)
        #expect(checkpoints.cue(for: progress(phaseDistance: 950)) == .upcomingTransition("Work 2"))
    }

    @Test func timedWorkBlockPlaysTheLastMinute() {
        var checkpoints = PhaseCheckpoints(
            phase: .work(setIndex: 0, target: .duration(300)),
            nextPhase: nil,
            config: CheckpointConfig(progress: [])
        )

        #expect(checkpoints.cue(for: progress(elapsed: 239)) == nil)
        #expect(checkpoints.cue(for: progress(elapsed: 240)) == .finalStretch(.lastMinute))
    }

    @Test func kilometerSplitGivesWayToTheLastKilometer() {
        var checkpoints = PhaseCheckpoints(
            phase: .work(setIndex: 0, target: .distance(meters: 3_000)),
            nextPhase: nil,
            config: CheckpointConfig(progress: [], isKilometerSplitEnabled: true)
        )

        #expect(checkpoints.cue(for: progress(phaseDistance: 1_000)) == .kilometerSplit(1))
        #expect(checkpoints.cue(for: progress(phaseDistance: 2_000)) == .finalStretch(.lastKilometer))
    }

    @Test func openRunKeepsCountingKilometers() {
        var checkpoints = PhaseCheckpoints(
            phase: .freeRun(goal: .free),
            nextPhase: nil,
            config: CheckpointConfig(isKilometerSplitEnabled: true)
        )

        #expect(checkpoints.cue(for: progress(phaseDistance: 1_000)) == .kilometerSplit(1))
        #expect(checkpoints.cue(for: progress(phaseDistance: 12_000)) == .kilometerSplit(12))
    }

    @Test func sessionDistanceCoveredBeforeTheBlockIsNotAnnounced() {
        var checkpoints = PhaseCheckpoints(
            phase: .freeRun(goal: .distance(meters: 5_000, scope: .totalSession)),
            nextPhase: nil,
            config: CheckpointConfig(progress: [], isFinalStretchEnabled: false, isKilometerSplitEnabled: true),
            startingAt: progress(sessionDistance: 1_200)
        )

        #expect(checkpoints.cue(for: progress(sessionDistance: 1_300)) == nil)
        #expect(checkpoints.cue(for: progress(sessionDistance: 2_000)) == .kilometerSplit(2))
    }

    @Test func gpsJumpPlaysOnlyTheMostImportantCue() {
        var checkpoints = PhaseCheckpoints(
            phase: .work(setIndex: 0, target: .distance(meters: 1_000)),
            nextPhase: .rest(setIndex: 0, target: .duration(90)),
            config: CheckpointConfig()
        )

        #expect(checkpoints.cue(for: progress(phaseDistance: 480)) == nil)
        #expect(checkpoints.cue(for: progress(phaseDistance: 960)) == .upcomingTransition("Rest 1"))
        #expect(checkpoints.cue(for: progress(phaseDistance: 990)) == nil)
    }
}
