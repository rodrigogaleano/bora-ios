import AVFoundation
import UIKit

final class SystemRunCuePlayer: RunCueProviding {
    private static let beepFrequency: Double = 880
    private static let beepDuration: TimeInterval = 0.12
    private static let beepInterval: TimeInterval = 0.2
    private static let clickFrequency: Double = 1_760
    private static let clickDuration: TimeInterval = 0.025
    private static let teardownPollInterval: Duration = .milliseconds(250)
    private static let teardownPollLimit = 24

    private let engine = AVAudioEngine()
    private let beepNode = AVAudioPlayerNode()
    private let metronomeNode = AVAudioPlayerNode()
    private let synthesizer = AVSpeechSynthesizer()
    private let format = AudioToneFactory.makeFormat()

    private var settings = RunSettings()
    private var isConfigured = false

    func prepare(settings: RunSettings) {
        self.settings = settings
        activateSession()
        startEngine()
    }

    func play(_ cue: RunCue) {
        let output = RunCueResolver.output(for: cue, settings: settings)
        guard !output.isSilent else { return }
        if output.beeps > 0 {
            playBeeps(output.beeps)
        }
        if let speech = output.speech {
            speak(speech)
        }
        if let haptic = output.haptic {
            trigger(haptic)
        }
    }

    func startMetronome(bpm: Int) {
        guard settings.isMetronomeEnabled, bpm > 0, let format, isConfigured else { return }
        let beat = 60 / Double(bpm)
        guard let buffer = AudioToneFactory.makeTone(
            format: format,
            frequency: Self.clickFrequency,
            duration: Self.clickDuration,
            totalDuration: beat,
            amplitude: 0.4
        ) else {
            return
        }
        metronomeNode.stop()
        metronomeNode.scheduleBuffer(buffer, at: nil, options: .loops)
        metronomeNode.play()
    }

    func stopMetronome() {
        metronomeNode.stop()
    }

    /// Lets whatever is already playing finish before releasing the session — callers tear
    /// down right after the final cue, and cutting the session would swallow it. Bounded so
    /// a stuck utterance can't hold the session (and the user's ducked music) forever.
    func teardown() {
        metronomeNode.stop()
        Task { [weak self] in
            for _ in 0..<Self.teardownPollLimit {
                guard let self, self.isPlayingAudio else { break }
                try? await Task.sleep(for: Self.teardownPollInterval)
            }
            self?.finalizeTeardown()
        }
    }

    private var isPlayingAudio: Bool {
        synthesizer.isSpeaking || beepNode.isPlaying
    }

    private func finalizeTeardown() {
        beepNode.stop()
        synthesizer.stopSpeaking(at: .immediate)
        engine.stop()
        isConfigured = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// `.playback` (not `.ambient`) is what keeps cues audible with the screen locked —
    /// the whole point of the feature. Ducking lets the user keep their own music on.
    private func activateSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers, .duckOthers])
        try? session.setActive(true)
    }

    private func startEngine() {
        guard let format else { return }
        if !isConfigured {
            engine.attach(beepNode)
            engine.attach(metronomeNode)
            engine.connect(beepNode, to: engine.mainMixerNode, format: format)
            engine.connect(metronomeNode, to: engine.mainMixerNode, format: format)
            isConfigured = true
        }
        guard !engine.isRunning else { return }
        do {
            try engine.start()
        } catch {
            isConfigured = false
        }
    }

    private func playBeeps(_ count: Int) {
        guard let format, isConfigured else { return }
        guard let buffer = AudioToneFactory.makeSequence(
            format: format,
            frequency: Self.beepFrequency,
            duration: Self.beepDuration,
            count: count,
            interval: Self.beepInterval
        ) else {
            return
        }
        beepNode.scheduleBuffer(buffer, at: nil)
        beepNode.play()
    }

    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.identifier)
            ?? AVSpeechSynthesisVoice(language: Locale.current.language.languageCode?.identifier)
        synthesizer.speak(utterance)
    }

    /// Haptics don't fire while the app is backgrounded or the screen is locked — audio is
    /// the real guidance channel there, and this is foreground reinforcement only.
    private func trigger(_ haptic: HapticStyle) {
        Task { @MainActor in
            switch haptic {
            case .light:
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            case .heavy:
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            case .success:
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
}
