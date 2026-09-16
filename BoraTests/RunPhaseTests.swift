import Testing
@testable import Bora

struct RunPhaseTests {
    @Test func runPhasesForHIITPlanProducesWorkRestPairsPerSet() {
        let plan = SessionPlan(
            goal: .free,
            warmup: .duration(60),
            hiit: HIITPlan(sets: 3, work: .duration(30), rest: .duration(15)),
            cooldown: .duration(60)
        )
        let kinds = plan.runPhases.map(\.kind)
        #expect(kinds == [
            .warmup,
            .work(setIndex: 0), .rest(setIndex: 0),
            .work(setIndex: 1), .rest(setIndex: 1),
            .work(setIndex: 2), .rest(setIndex: 2),
            .cooldown
        ])
    }

    @Test func runPhasesForNonHIITPlanProducesSingleFreeRunPhase() {
        let plan = SessionPlan(goal: .time(600), warmup: .duration(60), hiit: nil, cooldown: .duration(60))
        let kinds = plan.runPhases.map(\.kind)
        #expect(kinds == [.warmup, .freeRun, .cooldown])
    }

    @Test func runPhasesOmitsNilWarmupAndCooldown() {
        let plan = SessionPlan(goal: .free, warmup: nil, hiit: nil, cooldown: nil)
        #expect(plan.runPhases.map(\.kind) == [.freeRun])
    }

    @Test func isCompleteForDurationTargetTrueWhenElapsedReachesTarget() {
        let phase = RunPhase.warmup(target: .duration(60))
        #expect(!phase.isComplete(elapsed: 59, phaseDistanceMeters: 0, sessionDistanceMeters: 0))
        #expect(phase.isComplete(elapsed: 60, phaseDistanceMeters: 0, sessionDistanceMeters: 0))
    }

    @Test func isCompleteForDistanceTargetUsesPhaseDistance() {
        let phase = RunPhase.work(setIndex: 0, target: .distance(meters: 400))
        #expect(!phase.isComplete(elapsed: 999, phaseDistanceMeters: 399, sessionDistanceMeters: 999))
        #expect(phase.isComplete(elapsed: 0, phaseDistanceMeters: 400, sessionDistanceMeters: 0))
    }

    @Test func isCompleteForFreeRunWithTimeGoalUsesElapsed() {
        let phase = RunPhase.freeRun(goal: .time(1800))
        #expect(!phase.isComplete(elapsed: 1799, phaseDistanceMeters: 0, sessionDistanceMeters: 0))
        #expect(phase.isComplete(elapsed: 1800, phaseDistanceMeters: 0, sessionDistanceMeters: 0))
    }

    @Test func isCompleteForFreeRunWithDistanceGoalRunOnlyUsesPhaseDistance() {
        let phase = RunPhase.freeRun(goal: .distance(meters: 5000, scope: .runOnly))
        #expect(phase.isComplete(elapsed: 0, phaseDistanceMeters: 5000, sessionDistanceMeters: 0))
        #expect(!phase.isComplete(elapsed: 0, phaseDistanceMeters: 0, sessionDistanceMeters: 5000))
    }

    @Test func isCompleteForFreeRunWithDistanceGoalTotalSessionUsesSessionDistance() {
        let phase = RunPhase.freeRun(goal: .distance(meters: 5000, scope: .totalSession))
        #expect(phase.isComplete(elapsed: 0, phaseDistanceMeters: 0, sessionDistanceMeters: 5000))
        #expect(!phase.isComplete(elapsed: 0, phaseDistanceMeters: 5000, sessionDistanceMeters: 0))
    }

    @Test func isCompleteForFreeRunWithFreeGoalNeverCompletes() {
        let phase = RunPhase.freeRun(goal: .free)
        #expect(!phase.isComplete(elapsed: 1_000_000, phaseDistanceMeters: 1_000_000, sessionDistanceMeters: 1_000_000))
    }
}
