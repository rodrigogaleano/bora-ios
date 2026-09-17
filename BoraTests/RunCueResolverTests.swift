import Testing
@testable import Bora

struct RunCueResolverTests {
    private let allOff = RunSettings(
        isVoiceCueEnabled: false,
        isBeepEnabled: false,
        isHapticsEnabled: false
    )

    @Test func everythingDisabledProducesSilentOutput() {
        for cue in [RunCue.countdownTick(3), .phaseStarted("Warmup"), .upcomingTransition("Rest 1"), .runFinished] {
            #expect(RunCueResolver.output(for: cue, settings: allOff).isSilent)
        }
    }

    @Test func voiceDisabledStillBeeps() {
        var settings = RunSettings()
        settings.isVoiceCueEnabled = false

        let output = RunCueResolver.output(for: .phaseStarted("Warmup"), settings: settings)

        #expect(output.speech == nil)
        #expect(output.beeps == 1)
        #expect(output.haptic == .heavy)
    }

    @Test func beepsDisabledStillSpeaks() {
        var settings = RunSettings()
        settings.isBeepEnabled = false

        let output = RunCueResolver.output(for: .phaseStarted("Warmup"), settings: settings)

        #expect(output.speech == "Warmup")
        #expect(output.beeps == 0)
    }

    @Test func hapticsDisabledDoesNotAffectAudio() {
        var settings = RunSettings()
        settings.isHapticsEnabled = false

        let output = RunCueResolver.output(for: .runFinished, settings: settings)

        #expect(output.haptic == nil)
        #expect(output.beeps == 3)
        #expect(output.speech != nil)
    }

    @Test func countdownTickIsBeepOnlyWithoutSpeech() {
        let output = RunCueResolver.output(for: .countdownTick(3), settings: RunSettings())

        #expect(output.speech == nil)
        #expect(output.beeps == 1)
        #expect(output.haptic == .light)
    }

    @Test func upcomingTransitionSpeaksTheNameItReceived() {
        let output = RunCueResolver.output(for: .upcomingTransition("Rest 2"), settings: RunSettings())

        #expect(output.speech?.contains("Rest 2") == true)
        #expect(output.beeps == 2)
    }
}
