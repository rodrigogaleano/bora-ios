import Testing
@testable import Bora

struct PlanningViewModelTests {
    @Test func nextForwardsBuiltPlanWhenValid() {
        var forwardedPlan: SessionPlan?
        let viewModel = PlanningViewModel(clock: SystemClock()) { plan in
            forwardedPlan = plan
        }
        viewModel.goalKind = .free
        viewModel.next()
        #expect(forwardedPlan != nil)
    }

    @Test func nextDoesNothingWhenHIITIsInvalid() {
        var wasCalled = false
        let viewModel = PlanningViewModel(clock: SystemClock()) { _ in
            wasCalled = true
        }
        viewModel.goalKind = .free
        viewModel.isHIITEnabled = true
        viewModel.hiitSets = 0
        viewModel.next()
        #expect(!wasCalled)
    }

    @Test func timeGoalIsBuiltInSeconds() {
        let viewModel = PlanningViewModel(clock: SystemClock()) { _ in }
        viewModel.goalKind = .time
        #expect(viewModel.sessionPlan.goal == .time(1_800))
    }

    @Test func timedWarmupIsBuiltInSeconds() {
        let viewModel = PlanningViewModel(clock: SystemClock()) { _ in }
        viewModel.isWarmupEnabled = true
        viewModel.warmupKind = .duration
        #expect(viewModel.sessionPlan.warmup == .duration(300))
    }

    @Test func distanceGoalKeepsMeters() {
        let viewModel = PlanningViewModel(clock: SystemClock()) { _ in }
        viewModel.goalKind = .distance
        viewModel.goalDistanceMeters = 1_500
        #expect(viewModel.sessionPlan.goal == .distance(meters: 1_500, scope: .totalSession))
    }
}
