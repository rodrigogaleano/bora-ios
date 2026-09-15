import Testing
@testable import Bora

struct SessionPlanTests {
    @Test func distanceGoalIsValidWhenPositive() {
        let goal = SessionGoal.distance(meters: 5000, scope: .totalSession)
        #expect(goal.isValid)
    }

    @Test func distanceGoalIsInvalidWhenZero() {
        let goal = SessionGoal.distance(meters: 0, scope: .runOnly)
        #expect(!goal.isValid)
    }

    @Test func freeGoalIsAlwaysValid() {
        #expect(SessionGoal.free.isValid)
    }

    @Test func blockTargetIsInvalidWhenNonPositive() {
        #expect(!BlockTarget.duration(0).isValid)
        #expect(!BlockTarget.distance(meters: -10).isValid)
    }

    @Test func hiitPlanIsInvalidWhenSetsIsZero() {
        let hiit = HIITPlan(sets: 0, work: .duration(30), rest: .duration(30))
        #expect(!hiit.isValid)
    }

    @Test func sessionPlanIsValidWithOnlyGoalSet() {
        let plan = SessionPlan(goal: .free, warmup: nil, hiit: nil, cooldown: nil)
        #expect(plan.isValid)
    }

    @Test func sessionPlanIsInvalidWhenEnabledBlockIsInvalid() {
        let plan = SessionPlan(goal: .free, warmup: .duration(0), hiit: nil, cooldown: nil)
        #expect(!plan.isValid)
    }
}
