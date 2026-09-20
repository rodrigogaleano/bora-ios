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

    private static let recoveryRetryInterval: Duration = .seconds(2)
    private static let recoveryRetryLimit = 15

    private var engine = AVAudioEngine()
    private var beepNode = AVAudioPlayerNode()
    private var metronomeNode = AVAudioPlayerNode()
    private let synthesizer = AVSpeechSynthesizer()
    private let format = AudioToneFactory.makeFormat()

    private var settings = RunSettings()
    private var isConfigured = false
    private var isPrepared = false
    private var monitor = AudioSessionMonitor()
    private var recoveryTask: Task<Void, Never>?
    private var metronomeVolume = RunSettings().metronomeVolume
    /// What the metronome should be doing, so it can be brought back after the system
    /// stops the engine. Nil while it's off, paused or the run is over.
    private var desiredMetronomeBPM: Int?

    private(set) var isAudioAvailable = true

    /// The player lives as long as the app, so these observers are never removed.
    init() {
        observeAudioSession()
    }

    func prepare(settings: RunSettings) {
        self.settings = settings
        metronomeVolume = settings.metronomeVolume
        monitor = AudioSessionMonitor()
        isPrepared = true
        recover()
    }

    func play(_ cue: RunCue) {
        let output = RunCueResolver.output(for: cue, settings: settings)
        guard !output.isSilent else { return }
        if !isAudioAvailable, !monitor.isInterrupted {
            recover()
        }
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
        guard settings.isMetronomeEnabled, bpm > 0 else { return }
        desiredMetronomeBPM = bpm
        playMetronome(bpm: bpm)
    }

    func stopMetronome() {
        desiredMetronomeBPM = nil
        metronomeNode.stop()
    }

    func setMetronomeVolume(_ volume: Double) {
        metronomeVolume = volume
        metronomeNode.volume = Float(volume)
    }

    /// Lets whatever is already playing finish before releasing the session — callers tear
    /// down right after the final cue, and cutting the session would swallow it. Bounded so
    /// a stuck utterance can't hold the session (and the user's ducked music) forever.
    func teardown() {
        desiredMetronomeBPM = nil
        isPrepared = false
        recoveryTask?.cancel()
        recoveryTask = nil
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

    /// `AVAudioPlayerNode.play()` raises when the engine isn't running, and the system stops
    /// the engine on interruptions — so every playback path checks first.
    private func playMetronome(bpm: Int) {
        guard let format, isConfigured, engine.isRunning else { return }
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

    /// `.playback` (not `.ambient`) is what keeps cues audible with the screen locked —
    /// the whole point of the feature. Ducking lets the user keep their own music on.
    private func activateSession() -> Bool {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers, .duckOthers])
            try session.setActive(true)
            return true
        } catch {
            return false
        }
    }

    private func startEngine() -> Bool {
        guard let format else { return false }
        if !isConfigured {
            engine.attach(beepNode)
            engine.attach(metronomeNode)
            engine.connect(beepNode, to: engine.mainMixerNode, format: format)
            engine.connect(metronomeNode, to: engine.mainMixerNode, format: format)
            metronomeNode.volume = Float(metronomeVolume)
            isConfigured = true
        }
        guard !engine.isRunning else { return true }
        do {
            try engine.start()
            return true
        } catch {
            isConfigured = false
            return false
        }
    }

    private func playBeeps(_ count: Int) {
        guard let format, isConfigured, engine.isRunning else { return }
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

// MARK: - Recovery

extension SystemRunCuePlayer {
    private func handle(_ event: AudioSessionMonitor.Event) {
        guard isPrepared else { return }
        switch monitor.handle(event) {
        case .none:
            break
        case .recover:
            recover()
        case .rebuild:
            rebuild()
        }
    }

    /// Brings the session, engine and metronome back. On failure the runner is told through
    /// `isAudioAvailable`, and it retries on its own — right after a call ends the system
    /// often still refuses to hand the session back.
    private func recover() {
        if attemptRecovery() {
            recoveryTask?.cancel()
            recoveryTask = nil
        } else {
            scheduleRecoveryRetry()
        }
    }

    private func attemptRecovery() -> Bool {
        isAudioAvailable = activateSession() && startEngine()
        if isAudioAvailable, let bpm = desiredMetronomeBPM {
            playMetronome(bpm: bpm)
        }
        return isAudioAvailable
    }

    /// A media services reset invalidates the engine and every node attached to it.
    private func rebuild() {
        engine.stop()
        engine = AVAudioEngine()
        beepNode = AVAudioPlayerNode()
        metronomeNode = AVAudioPlayerNode()
        isConfigured = false
        recover()
    }

    private func scheduleRecoveryRetry() {
        guard recoveryTask == nil else { return }
        recoveryTask = Task { [weak self] in
            for _ in 0..<Self.recoveryRetryLimit {
                try? await Task.sleep(for: Self.recoveryRetryInterval)
                guard let self, !Task.isCancelled, isPrepared else { return }
                // A new interruption is in progress: its end triggers the recovery instead.
                if !monitor.isInterrupted, attemptRecovery() { break }
            }
            self?.recoveryTask = nil
        }
    }

    private func observeAudioSession() {
        observe(AVAudioSession.interruptionNotification) { note in
            let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            switch raw.flatMap(AVAudioSession.InterruptionType.init(rawValue:)) {
            case .began: return .interruptionBegan
            case .ended: return .interruptionEnded
            default: return nil
            }
        }
        observe(AVAudioSession.routeChangeNotification) { note in
            let raw = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            return raw.flatMap(AVAudioSession.RouteChangeReason.init(rawValue:)).map { .routeChanged($0) }
        }
        observe(.AVAudioEngineConfigurationChange) { _ in .engineConfigurationChanged }
        observe(AVAudioSession.mediaServicesWereResetNotification) { _ in .mediaServicesReset }
    }

    private func observe(
        _ name: Notification.Name,
        event: @escaping @Sendable (Notification) -> AudioSessionMonitor.Event?
    ) {
        NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] note in
            guard let event = event(note) else { return }
            MainActor.assumeIsolated { self?.handle(event) }
        }
    }
}
