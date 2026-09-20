import Foundation

/// Tracks whether a run is still receiving usable GPS fixes. Pure on purpose: the run only
/// has to feed it timestamps and react to the transitions it reports.
struct GPSSignalMonitor {
    /// How long a run can go without a usable fix before distance is considered to have
    /// stopped counting. Also the grace period at the start while the GPS warms up.
    static let timeout: TimeInterval = 15

    private(set) var isLost = false
    private var lastValidFixAt: Date

    init(startedAt: Date) {
        lastValidFixAt = startedAt
    }

    /// - Returns: `true` if this call is what flipped the signal to lost.
    mutating func checkTimeout(now: Date) -> Bool {
        guard !isLost, now.timeIntervalSince(lastValidFixAt) >= Self.timeout else { return false }
        isLost = true
        return true
    }

    /// - Returns: `true` if this fix is what brought the signal back.
    mutating func recordValidFix(at now: Date) -> Bool {
        lastValidFixAt = now
        guard isLost else { return false }
        isLost = false
        return true
    }

    /// Fixes are ignored while a run is paused, so the silence in between isn't signal loss.
    mutating func resume(at now: Date) {
        lastValidFixAt = now
    }
}
