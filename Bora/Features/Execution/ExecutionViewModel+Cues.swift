import Foundation

extension ExecutionViewModel {
    func announceCurrentPhase(recap: RepRecap? = nil) {
        guard let currentPhase else { return }
        pacer = PhasePacer()
        checkpoints = PhaseCheckpoints(
            phase: currentPhase,
            nextPhase: nextPhase,
            config: plan.checkpoints,
            startingAt: PhaseCheckpoints.Progress(
                elapsed: 0,
                phaseDistanceMeters: 0,
                sessionDistanceMeters: totalDistanceMeters
            )
        )
        cuePlayer.play(.phaseStarted(currentPhase.kind.displayName, recap: recap))
        startMetronomeIfNeeded()
    }

    /// The metronome is a cadence guide, so it stays quiet while the runner is resting.
    func startMetronomeIfNeeded() {
        guard settings.isMetronomeEnabled, runState == .running, let currentPhase else { return }
        if case .rest = currentPhase.kind {
            cuePlayer.stopMetronome()
            return
        }
        cuePlayer.startMetronome(bpm: settings.metronomeBPM)
    }

    func playCheckpointIfReached() {
        let progress = PhaseCheckpoints.Progress(
            elapsed: elapsedInPhase,
            phaseDistanceMeters: phaseDistanceMeters,
            sessionDistanceMeters: totalDistanceMeters
        )
        if let cue = checkpoints?.cue(for: progress) {
            cuePlayer.play(
                pacer.pacing(cue, elapsed: elapsedInPhase, meters: phaseDistanceMeters, isSignalLost: isGPSSignalLost)
            )
        }
    }

    func repRecap() -> RepRecap? {
        guard plan.checkpoints.isRepSummaryEnabled, let currentPhase else { return nil }
        return PhasePacer.recap(
            for: currentPhase,
            elapsed: elapsedInPhase,
            meters: phaseDistanceMeters,
            isSignalLost: isGPSSignalLost
        )
    }
}
