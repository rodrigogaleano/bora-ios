import Foundation

@Observable
final class ResultsViewModel {
    private let clock: ClockProviding
    let metrics: SessionMetrics
    private let onDone: () -> Void

    init(clock: ClockProviding, metrics: SessionMetrics, onDone: @escaping () -> Void) {
        self.clock = clock
        self.metrics = metrics
        self.onDone = onDone
    }

    var title: String { "Results Screen" }

    func done() {
        onDone()
    }
}
