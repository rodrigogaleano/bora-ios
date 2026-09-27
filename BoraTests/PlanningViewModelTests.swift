import Testing
@testable import Bora

struct PlanningViewModelTests {
    private func makeViewModel(
        _ workoutType: WorkoutType,
        onNext: @escaping (SessionPlan) -> Void = { _ in }
    ) -> PlanningViewModel {
        PlanningViewModel(workoutType: workoutType, clock: SystemClock(), onNext: onNext)
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
}
