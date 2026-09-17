/// Records what was asked of it instead of making any sound, so the run state machine can
/// be tested without audio hardware.
final class PreviewRunCuePlayer: RunCueProviding {
    private(set) var preparedSettings: RunSettings?
    private(set) var playedCues: [RunCue] = []
    private(set) var metronomeBPM: Int?
    private(set) var isTornDown = false

    var isMetronomeRunning: Bool { metronomeBPM != nil }

    func prepare(settings: RunSettings) {
        preparedSettings = settings
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

    func teardown() {
        metronomeBPM = nil
        isTornDown = true
    }
}
