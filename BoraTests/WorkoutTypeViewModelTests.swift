import Testing
@testable import Bora

struct WorkoutTypeViewModelTests {
    @Test func listsEveryWorkoutType() {
        let viewModel = WorkoutTypeViewModel { _ in }
        #expect(viewModel.types == WorkoutType.allCases)
    }

    @Test func selectForwardsTheType() {
        var selected: WorkoutType?
        let viewModel = WorkoutTypeViewModel { selected = $0 }
        viewModel.select(.longRun)
        #expect(selected == .longRun)
    }
}
