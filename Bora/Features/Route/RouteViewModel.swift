import Foundation

@Observable
final class RouteViewModel {
    private let clock: ClockProviding
    private let onNext: () -> Void

    init(clock: ClockProviding, onNext: @escaping () -> Void) {
        self.clock = clock
        self.onNext = onNext
    }

    var title: String { "Route Screen" }

    func next() {
        onNext()
    }
}
