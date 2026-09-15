import Foundation

@Observable
final class RouteViewModel {
    private let clock: ClockProviding
    let plan: SessionPlan
    private let onNext: () -> Void

    init(clock: ClockProviding, plan: SessionPlan, onNext: @escaping () -> Void) {
        self.clock = clock
        self.plan = plan
        self.onNext = onNext
    }

    var title: String { "Route Screen" }

    func next() {
        onNext()
    }
}
