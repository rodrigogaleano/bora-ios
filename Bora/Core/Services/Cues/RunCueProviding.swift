/// A moment in a run worth announcing. The associated strings are already localized by
/// the caller — the player doesn't know about `RunPhase` or the string catalog.
enum RunCue: Hashable {
    case countdownTick(Int)
    case phaseStarted(String)
    case upcomingTransition(String)
    case runFinished
    case gpsLost
    case gpsRecovered
}

protocol RunCueProviding {
    /// False while the audio session or engine couldn't be brought back after an
    /// interruption — cues and the metronome are muted until it recovers.
    var isAudioAvailable: Bool { get }

    /// Configures the audio session and caches the toggles this run should honor.
    func prepare(settings: RunSettings)
    func play(_ cue: RunCue)
    func startMetronome(bpm: Int)
    func stopMetronome()
    /// Takes effect immediately, even while the metronome is already ticking.
    func setMetronomeVolume(_ volume: Double)
    /// Releases the audio session so other apps get their volume back.
    func teardown()
}
