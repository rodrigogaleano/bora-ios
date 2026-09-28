import Testing
@testable import Bora

struct PlanningViewModelTests {
    private func makeViewModel(
        _ workoutType: WorkoutType,
        lastWorkouts: PreviewLastWorkoutStore = PreviewLastWorkoutStore(),
        onNext: @escaping (SessionPlan) -> Void = { _ in }
    ) -> PlanningViewModel {
        PlanningViewModel(workoutType: workoutType, clock: SystemClock(), lastWorkouts: lastWorkouts, onNext: onNext)
    }

    @Test func nextForwardsBuiltPlanWhenValid() {
        var forwardedPlan: SessionPlan?
        let viewModel = makeViewModel(.freeRun) { forwardedPlan = $0 }
        viewModel.next()
        #expect(forwardedPlan != nil)
    }

    @Test func nextDoesNothingWhenHIITIsInvalid() {
        var wasCalled = false
        let viewModel = makeViewModel(.intervals) { _ in wasCalled = true }
        viewModel.hiitSets = 0
        viewModel.next()
        #expect(!wasCalled)
    }

    @Test func timedWarmupIsBuiltInSeconds() {
        let viewModel = makeViewModel(.freeRun)
        viewModel.isWarmupEnabled = true
        viewModel.warmupKind = .duration
        #expect(viewModel.sessionPlan.warmup == .duration(300))
    }

    @Test func distanceGoalKeepsMeters() {
        let viewModel = makeViewModel(.longRun)
        viewModel.goalDistanceMeters = 1_500
        #expect(viewModel.sessionPlan.goal == .distance(meters: 1_500, scope: .totalSession))
    }

    @Test func planCarriesTheWorkoutType() {
        #expect(makeViewModel(.longRun).sessionPlan.workoutType == .longRun)
    }

    @Test func easyRunDefaultsToFortyMinutes() {
        let plan = makeViewModel(.easyRun).sessionPlan
        #expect(plan.goal == .time(2_400))
        #expect(plan.hiit == nil)
    }

    @Test func longRunDefaultsToTenKilometers() {
        let plan = makeViewModel(.longRun).sessionPlan
        #expect(plan.goal == .distance(meters: 10_000, scope: .totalSession))
        #expect(plan.hiit == nil)
    }

    @Test func intervalsDefaultToRepeatsWithWarmupAndCooldown() {
        let plan = makeViewModel(.intervals).sessionPlan
        #expect(plan.goal == .free)
        #expect(plan.hiit == HIITPlan(sets: 6, work: .distance(meters: 400), rest: .duration(90)))
        #expect(plan.warmup == .duration(600))
        #expect(plan.cooldown == .duration(600))
    }

    @Test func freeRunNeverBuildsIntervals() {
        let viewModel = makeViewModel(.freeRun)
        viewModel.isHIITEnabled = true
        #expect(viewModel.sessionPlan.goal == .free)
        #expect(viewModel.sessionPlan.hiit == nil)
    }

    @Test func intervalsIgnoreTheGoalKind() {
        let viewModel = makeViewModel(.intervals)
        viewModel.goalKind = .distance
        #expect(viewModel.sessionPlan.goal == .free)
    }

    @Test func longRunCountsKilometersAndIntervalsSummarizeReps() {
        let longRun = makeViewModel(.longRun).sessionPlan.checkpoints
        let intervals = makeViewModel(.intervals).sessionPlan.checkpoints

        #expect(longRun.isKilometerSplitEnabled)
        #expect(!longRun.isRepSummaryEnabled)
        #expect(!intervals.isKilometerSplitEnabled)
        #expect(intervals.isRepSummaryEnabled)
    }

    @Test func progressChoicesReachThePlan() {
        let viewModel = makeViewModel(.longRun)

        viewModel.setProgressCheckpoint(.quarter, isOn: true)
        viewModel.setProgressCheckpoint(.half, isOn: false)

        #expect(viewModel.sessionPlan.checkpoints.progress == [.quarter])
    }

    @Test func freeRunHidesProgressAndOnlyIntervalsShowRepSummary() {
        #expect(!makeViewModel(.freeRun).showsProgressCheckpoints)
        #expect(makeViewModel(.easyRun).showsProgressCheckpoints)
        #expect(makeViewModel(.intervals).showsRepSummary)
        #expect(!makeViewModel(.longRun).showsRepSummary)
    }

    @Test func reopensTheLastIntervalsWorkout() {
        var checkpoints = WorkoutType.intervals.defaultCheckpoints
        checkpoints.isKilometerSplitEnabled = true
        let saved = SessionPlan(
            goal: .free,
            warmup: .distance(meters: 1_000),
            hiit: HIITPlan(sets: 8, work: .distance(meters: 1_000), rest: .duration(120)),
            cooldown: nil,
            workoutType: .intervals,
            checkpoints: checkpoints
        )
        let viewModel = makeViewModel(.intervals, lastWorkouts: PreviewLastWorkoutStore(plans: [.intervals: saved]))

        #expect(viewModel.hiitSets == 8)
        #expect(!viewModel.isCooldownEnabled)
        #expect(viewModel.sessionPlan == saved)
    }

    @Test func reopensTheLastLongRunGoal() {
        let saved = SessionPlan(goal: .time(5_400), workoutType: .longRun)
        let viewModel = makeViewModel(.longRun, lastWorkouts: PreviewLastWorkoutStore(plans: [.longRun: saved]))

        #expect(viewModel.goalKind == .time)
        #expect(viewModel.goalDurationSeconds == 5_400)
    }

    @Test func nextRemembersThePlanForItsType() {
        let store = PreviewLastWorkoutStore()
        let viewModel = makeViewModel(.intervals, lastWorkouts: store)
        viewModel.hiitSets = 8

        viewModel.next()

        #expect(store.load(.intervals)?.hiit?.sets == 8)
        #expect(store.load(.longRun) == nil)
    }
}
