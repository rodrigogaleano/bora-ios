import Foundation

@Observable
final class PlanningViewModel {
    private let clock: ClockProviding
    private let onNext: () -> Void

    init(clock: ClockProviding, onNext: @escaping () -> Void) {
        self.clock = clock
        self.onNext = onNext
    }

    var title: String { "Planning Screen" }

    func next() {
        onNext()
    }
}
