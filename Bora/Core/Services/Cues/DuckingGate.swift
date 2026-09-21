/// Decides when the cue player should lower other apps' audio. Pure on purpose, like
/// `AudioSessionMonitor`: the player only executes the returned action, so the timing rules
/// are testable without audio hardware.
///
/// Ducking is held for a moment after the last sound so a countdown (one beep per second)
/// doesn't make the runner's music pump up and down between beeps.
struct DuckingGate {
    nonisolated enum Action: Equatable {
        case none
        /// Lower the other apps' audio.
        case duck
        /// Give the other apps their volume back.
        case release
    }

    static let holdDuration: Duration = .milliseconds(1_500)

    private(set) var isDucking = false
    /// Beeps and speech can overlap, so ducking ends only when every sound has.
    private var activeSounds = 0
    private var releaseAt: ContinuousClock.Instant?

    mutating func soundStarted() -> Action {
        activeSounds += 1
        releaseAt = nil
        guard !isDucking else { return .none }
        isDucking = true
        return .duck
    }

    /// Returns when the hold ends so the caller can wake up then, or nil while other sounds
    /// are still playing.
    mutating func soundFinished(at now: ContinuousClock.Instant) -> ContinuousClock.Instant? {
        activeSounds = max(0, activeSounds - 1)
        guard activeSounds == 0, isDucking else { return nil }
        let deadline = now.advanced(by: Self.holdDuration)
        releaseAt = deadline
        return deadline
    }

    mutating func releaseIfDue(at now: ContinuousClock.Instant) -> Action {
        guard isDucking, activeSounds == 0, let releaseAt, now >= releaseAt else { return .none }
        isDucking = false
        self.releaseAt = nil
        return .release
    }

    /// For when the sounds were cut short (interruption, media services reset, teardown)
    /// and their completions can't be trusted to arrive.
    mutating func reset() {
        isDucking = false
        activeSounds = 0
        releaseAt = nil
    }
}
