protocol LastWorkoutStoring {
    func load(_ workoutType: WorkoutType) -> SessionPlan?
    func save(_ plan: SessionPlan)
}
