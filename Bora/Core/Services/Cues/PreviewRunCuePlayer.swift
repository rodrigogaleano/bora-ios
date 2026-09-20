/// Records what was asked of it instead of making any sound, so the run state machine can
/// be tested without audio hardware.
final class PreviewRunCuePlayer: RunCueProviding {
    var isAudioAvailable = true
    private(set) var preparedSettings: RunSettings?
    private(set) var playedCues: [RunCue] = []
    private(set) var metronomeBPM: Int?
    private(set) var metronomeVolume: Double?
    private(set) var isTornDown = false

    var isMetronomeRunning: Bool { metronomeBPM != nil }

    func prepare(settings: RunSettings) {
        preparedSettings = settings
        metronomeVolume = settings.metronomeVolume
    }

    func play(_ cue: RunCue) {
        playedCues.append(cue)
    }

    func startMetronome(bpm: Int) {
        metronomeBPM = bpm
    }

    func stopMetronome() {
        metronomeBPM = nil
    }

    func setMetronomeVolume(_ volume: Double) {
        metronomeVolume = volume
    }

    func teardown() {
        metronomeBPM = nil
        isTornDown = true
    }
}
