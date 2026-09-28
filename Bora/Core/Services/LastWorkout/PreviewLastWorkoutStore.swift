final class PreviewLastWorkoutStore: LastWorkoutStoring {
    private(set) var plans: [WorkoutType: SessionPlan]

    init(plans: [WorkoutType: SessionPlan] = [:]) {
        self.plans = plans
    }

    func load(_ workoutType: WorkoutType) -> SessionPlan? {
        plans[workoutType]
    }

    func save(_ plan: SessionPlan) {
        guard let workoutType = plan.workoutType else { return }
        plans[workoutType] = plan
    }
}
