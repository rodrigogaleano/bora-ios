import Foundation

@Observable
final class ExecutionViewModel {
    private let clock: ClockProviding
    let plan: SessionPlan
    let route: PlannedRoute
    private let onNext: () -> Void

    init(clock: ClockProviding, plan: SessionPlan, route: PlannedRoute, onNext: @escaping () -> Void) {
        self.clock = clock
        self.plan = plan
        self.route = route
        self.onNext = onNext
    }

    var title: String { "Execution Screen" }

    func next() {
        onNext()
    }
}
