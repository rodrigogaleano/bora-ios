import Foundation

@Observable
final class ResultsViewModel {
    private let clock: ClockProviding
    private let onDone: () -> Void

    init(clock: ClockProviding, onDone: @escaping () -> Void) {
        self.clock = clock
        self.onDone = onDone
    }

    var title: String { "Results Screen" }

    func done() {
        onDone()
    }
}
