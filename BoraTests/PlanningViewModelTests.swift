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
}
