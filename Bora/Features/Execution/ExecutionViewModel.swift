import Foundation

@Observable
final class ExecutionViewModel {
    private let clock: ClockProviding
    private let onNext: () -> Void

    init(clock: ClockProviding, onNext: @escaping () -> Void) {
        self.clock = clock
        self.onNext = onNext
    }

    var title: String { "Execution Screen" }

    func next() {
        onNext()
    }
}
