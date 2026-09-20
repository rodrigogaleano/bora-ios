import AVFoundation

/// Decides what the cue player should do when the system disturbs its audio. Pure on
/// purpose, like `GPSSignalMonitor`: the player only executes the returned action, so the
/// interplay between interruptions and route changes is testable without audio hardware.
struct AudioSessionMonitor {
    nonisolated enum Event: Equatable {
        case interruptionBegan
        case interruptionEnded
        case routeChanged(AVAudioSession.RouteChangeReason)
        case engineConfigurationChanged
        case mediaServicesReset
    }

    nonisolated enum Action: Equatable {
        case none
        /// Reactivate the session and restart the engine and metronome.
        case recover
        /// The engine and its nodes are invalid: recreate them, then recover.
        case rebuild
    }

    private(set) var isInterrupted = false

    mutating func handle(_ event: Event) -> Action {
        switch event {
        case .interruptionBegan:
            isInterrupted = true
            return .none
        case .interruptionEnded:
            // The `shouldResume` hint is ignored on purpose: a phone call usually reports
            // `false`, yet the run is still going and the runner still needs the cues.
            isInterrupted = false
            return .recover
        case .routeChanged(let reason):
            return Self.reroutes(reason) ? recoverUnlessInterrupted() : .none
        case .engineConfigurationChanged:
            return recoverUnlessInterrupted()
        case .mediaServicesReset:
            isInterrupted = false
            return .rebuild
        }
    }

    /// Something the engine can stop for: headphones gone or arrived, or another app
    /// taking the route. Anything else (sleep/wake, category tweaks) leaves it running.
    private static func reroutes(_ reason: AVAudioSession.RouteChangeReason) -> Bool {
        switch reason {
        case .oldDeviceUnavailable, .newDeviceAvailable, .override:
            return true
        default:
            return false
        }
    }

    /// While a call is in progress the session can't be reactivated; the end of the
    /// interruption is what brings the audio back.
    private func recoverUnlessInterrupted() -> Action {
        isInterrupted ? .none : .recover
    }
}
