import Testing
@testable import Bora

struct RunCueResolverTests {
    private let allOff = RunSettings(
        isVoiceCueEnabled: false,
        isBeepEnabled: false,
        isHapticsEnabled: false
    )

    @Test func everythingDisabledProducesSilentOutput() {
        let cues: [RunCue] = [
            .countdownTick(3), .phaseStarted("Warmup"), .upcomingTransition("Rest 1"), .runEnding, .runFinished(),
            .gpsLost, .gpsRecovered, .progress(.half), .finalStretch(.last100Meters), .kilometerSplit(2)
        ]
        for cue in cues {
            #expect(RunCueResolver.output(for: cue, settings: allOff).isSilent)
        }
    }

    @Test func gpsLostIsAnUrgentCueWithSpeechBeepsAndHaptic() {
        let output = RunCueResolver.output(for: .gpsLost, settings: RunSettings())

        #expect(output.speech != nil)
        #expect(output.beeps == 2)
        #expect(output.haptic == .heavy)
    }

    @Test func gpsRecoveredIsAShorterCueThanGpsLost() {
        let output = RunCueResolver.output(for: .gpsRecovered, settings: RunSettings())

        #expect(output.speech != nil)
        #expect(output.beeps == 1)
        #expect(output.haptic == .light)
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

        let output = RunCueResolver.output(for: .runFinished(), settings: settings)

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

    @Test func runEndingIsAnnouncedLikeATransition() {
        let output = RunCueResolver.output(for: .runEnding, settings: RunSettings())

        #expect(output.speech != nil)
        #expect(output.beeps == 2)
        #expect(output.haptic == .light)
    }

    @Test func checkpointsAreLighterThanTransitions() {
        let cues: [RunCue] = [.progress(.half), .finalStretch(.lastMinute), .kilometerSplit(1)]
        for cue in cues {
            let output = RunCueResolver.output(for: cue, settings: RunSettings())

            #expect(output.speech != nil)
            #expect(output.beeps == 1)
            #expect(output.haptic == .light)
        }
    }

    @Test func kilometerSplitSpeaksTheDistance() {
        let output = RunCueResolver.output(for: .kilometerSplit(3), settings: RunSettings())

        #expect(output.speech?.contains("3") == true)
    }

    @Test func nextBlockCarriesTheRepSummary() {
        let recap = RepRecap(measure: .time(92), paceSecondsPerKm: 230)
        let output = RunCueResolver.output(for: .phaseStarted("Rest 3", recap: recap), settings: RunSettings())

        #expect(output.speech == "Rest 3. Rep: 1 minute, 32 seconds, pace 3 50")
    }

    @Test func timedRepSpeaksTheDistance() {
        let recap = RepRecap(measure: .distance(meters: 283), paceSecondsPerKm: nil)
        let output = RunCueResolver.output(for: .phaseStarted("Rest 1", recap: recap), settings: RunSettings())

        #expect(output.speech == "Rest 1. Rep: \(RunSpeechFormatting.distance(meters: 283))")
    }

    @Test func kilometerSplitSpeaksItsPace() {
        let output = RunCueResolver.output(for: .kilometerSplit(5, pace: 342), settings: RunSettings())

        #expect(output.speech == "5 kilometers, pace 5 42")
    }

    @Test func finishedSpeaksTheRepsAverage() {
        let cue = RunCue.runFinished(pace: FinalPace(secondsPerKm: 232, isRepsOnly: true))
        let output = RunCueResolver.output(for: cue, settings: RunSettings())

        #expect(output.speech == "Finished. Reps average, pace 3 52")
    }
}
