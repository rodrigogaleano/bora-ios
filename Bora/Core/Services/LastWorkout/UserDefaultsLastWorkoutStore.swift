import Foundation

final class UserDefaultsLastWorkoutStore: LastWorkoutStoring {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load(_ workoutType: WorkoutType) -> SessionPlan? {
        guard let data = defaults.data(forKey: Self.key(for: workoutType)) else { return nil }
        return try? JSONDecoder().decode(SessionPlan.self, from: data)
    }

    func save(_ plan: SessionPlan) {
        guard
            let workoutType = plan.workoutType,
            let data = try? JSONEncoder().encode(plan)
        else { return }
        defaults.set(data, forKey: Self.key(for: workoutType))
    }

    static func key(for workoutType: WorkoutType) -> String {
        "last_workout_\(workoutType.rawValue)"
    }
}
