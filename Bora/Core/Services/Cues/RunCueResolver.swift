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
        case .phaseStarted(let name):
            return Output(speech: name, beeps: 1, haptic: .heavy)
        case .upcomingTransition(let name):
            return Output(speech: String(localized: "Coming up: \(name)"), beeps: 2, haptic: .light)
        case .runFinished:
            return Output(speech: String(localized: "Finished"), beeps: 3, haptic: .success)
        }
    }
}
