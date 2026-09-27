import Foundation

enum HapticStyle: Hashable {
    case light
    case heavy
    case success
}

/// Pure translation of a cue plus the user's toggles into what should actually come out.
/// Keeping this separate from `SystemRunCuePlayer` is what makes the gating testable —
/// the player only executes an `Output`.
enum RunCueResolver {
    struct Output: Equatable {
        var speech: String?
        var beeps: Int = 0
        var haptic: HapticStyle?

        var isSilent: Bool {
            speech == nil && beeps == 0 && haptic == nil
        }
    }

    static func output(for cue: RunCue, settings: RunSettings) -> Output {
        var output = unfilteredOutput(for: cue)
        if !settings.isVoiceCueEnabled {
            output.speech = nil
        }
        if !settings.isBeepEnabled {
            output.beeps = 0
        }
        if !settings.isHapticsEnabled {
            output.haptic = nil
        }
        return output
    }

    private static func unfilteredOutput(for cue: RunCue) -> Output {
        switch cue {
        case .countdownTick:
            return Output(beeps: 1, haptic: .light)
        case .phaseStarted(let name, let recap):
            return Output(speech: sentences([name, recap?.spokenSummary]), beeps: 1, haptic: .heavy)
        case .upcomingTransition(let name):
            return Output(speech: String(localized: "Coming up: \(name)"), beeps: 2, haptic: .light)
        case .runEnding:
            return Output(speech: String(localized: "Almost done"), beeps: 2, haptic: .light)
        case .progress(let checkpoint, let pace):
            return Output(speech: withPace(checkpoint.spokenName, pace), beeps: 1, haptic: .light)
        case .finalStretch(let stretch):
            return Output(speech: stretch.spokenName, beeps: 1, haptic: .light)
        case .kilometerSplit(let kilometers, let pace):
            let speech = withPace(String(localized: "\(kilometers) kilometers"), pace)
            return Output(speech: speech, beeps: 1, haptic: .light)
        case .runFinished(let recap, let pace):
            let speech = sentences([String(localized: "Finished"), recap?.spokenSummary, pace?.spokenSummary])
            return Output(speech: speech, beeps: 3, haptic: .success)
        case .gpsLost:
            return Output(speech: String(localized: "GPS signal lost"), beeps: 2, haptic: .heavy)
        case .gpsRecovered:
            return Output(speech: String(localized: "GPS signal back"), beeps: 1, haptic: .light)
        }
    }

    private static func sentences(_ parts: [String?]) -> String {
        parts.compactMap { $0 }.joined(separator: ". ")
    }

    private static func withPace(_ text: String, _ secondsPerKm: Double?) -> String {
        guard let secondsPerKm else { return text }
        return "\(text), \(RunSpeechFormatting.pace(secondsPerKm: secondsPerKm))"
    }
}

private extension RepRecap {
    var spokenSummary: String {
        let value: String
        switch measure {
        case .time(let seconds):
            value = RunSpeechFormatting.duration(seconds)
        case .distance(let meters):
            value = RunSpeechFormatting.distance(meters: meters)
        }
        let summary = String(localized: "Rep: \(value)")
        guard let paceSecondsPerKm else { return summary }
        return "\(summary), \(RunSpeechFormatting.pace(secondsPerKm: paceSecondsPerKm))"
    }
}

private extension FinalPace {
    var spokenSummary: String {
        let label = isRepsOnly ? String(localized: "Reps average") : String(localized: "Average")
        return "\(label), \(RunSpeechFormatting.pace(secondsPerKm: secondsPerKm))"
    }
}

private extension ProgressCheckpoint {
    var spokenName: String {
        switch self {
        case .quarter:
            return String(localized: "Quarter done")
        case .half:
            return String(localized: "Halfway")
        case .threeQuarters:
            return String(localized: "Three quarters")
        case .ninety:
            return String(localized: "Almost there")
        }
    }
}

private extension FinalStretch {
    var spokenName: String {
        switch self {
        case .lastKilometer:
            return String(localized: "Last kilometer")
        case .last100Meters:
            return String(localized: "Last 100 meters")
        case .lastMinute:
            return String(localized: "Last minute")
        }
    }
}
