import Foundation

@Observable
final class WorkoutTypeViewModel {
    let types = WorkoutType.allCases

    private let onSelect: (WorkoutType) -> Void

    init(onSelect: @escaping (WorkoutType) -> Void) {
        self.onSelect = onSelect
    }

    func select(_ type: WorkoutType) {
        onSelect(type)
    }
}
