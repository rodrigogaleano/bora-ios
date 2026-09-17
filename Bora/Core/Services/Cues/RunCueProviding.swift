/// A moment in a run worth announcing. The associated strings are already localized by
/// the caller — the player doesn't know about `RunPhase` or the string catalog.
enum RunCue: Hashable {
    case countdownTick(Int)
    case phaseStarted(String)
    case upcomingTransition(String)
    case runFinished
}

protocol RunCueProviding {
    /// Configures the audio session and caches the toggles this run should honor.
    func prepare(settings: RunSettings)
    func play(_ cue: RunCue)
    func startMetronome(bpm: Int)
    func stopMetronome()
    /// Releases the audio session so other apps get their volume back.
    func teardown()
}
