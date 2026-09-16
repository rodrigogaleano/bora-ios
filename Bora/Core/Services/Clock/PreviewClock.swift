import Foundation

final class PreviewClock: ClockProviding {
    var now: Date

    init(now: Date = .now) {
        self.now = now
    }

    func advance(by seconds: TimeInterval) {
        now = now.addingTimeInterval(seconds)
    }
}
