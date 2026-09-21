import Testing
@testable import Bora

struct DuckingGateTests {
    private let start = ContinuousClock.now

    private var afterHold: ContinuousClock.Instant {
        start.advanced(by: DuckingGate.holdDuration)
    }

    @Test func firstSoundDucks() {
        var gate = DuckingGate()

        #expect(gate.soundStarted() == .duck)
        #expect(gate.isDucking)
    }

    @Test func laterSoundsWhileDuckingDoNothing() {
        var gate = DuckingGate()
        _ = gate.soundStarted()

        #expect(gate.soundStarted() == .none)
    }

    @Test func releasesOnlyAfterTheHold() {
        var gate = DuckingGate()
        _ = gate.soundStarted()
        let deadline = gate.soundFinished(at: start)

        #expect(deadline == afterHold)
        #expect(gate.releaseIfDue(at: start.advanced(by: .milliseconds(500))) == .none)
        #expect(gate.isDucking)
        #expect(gate.releaseIfDue(at: afterHold) == .release)
        #expect(!gate.isDucking)
    }

    @Test func overlappingSoundsReleaseOnlyWhenBothEnd() {
        var gate = DuckingGate()
        _ = gate.soundStarted()
        _ = gate.soundStarted()

        #expect(gate.soundFinished(at: start) == nil)
        #expect(gate.releaseIfDue(at: afterHold) == .none)
        #expect(gate.soundFinished(at: start) == afterHold)
        #expect(gate.releaseIfDue(at: afterHold) == .release)
    }

    @Test func soundInsideTheHoldCancelsTheRelease() {
        var gate = DuckingGate()
        _ = gate.soundStarted()
        _ = gate.soundFinished(at: start)

        #expect(gate.soundStarted() == .none)
        #expect(gate.releaseIfDue(at: afterHold) == .none)
        #expect(gate.isDucking)
    }

    @Test func countdownKeepsDuckingBetweenBeeps() {
        var gate = DuckingGate()
        _ = gate.soundStarted()
        _ = gate.soundFinished(at: start)
        let nextBeep = start.advanced(by: .seconds(1))
        _ = gate.soundStarted()
        _ = gate.soundFinished(at: nextBeep.advanced(by: .milliseconds(200)))

        #expect(gate.releaseIfDue(at: nextBeep.advanced(by: .milliseconds(300))) == .none)
        #expect(gate.isDucking)
    }

    @Test func ducksAgainForTheNextCueAfterRelease() {
        var gate = DuckingGate()
        _ = gate.soundStarted()
        _ = gate.soundFinished(at: start)
        _ = gate.releaseIfDue(at: afterHold)

        #expect(gate.soundStarted() == .duck)
    }

    @Test func strayCompletionsDontGoNegative() {
        var gate = DuckingGate()

        #expect(gate.soundFinished(at: start) == nil)
        #expect(gate.soundStarted() == .duck)
        #expect(gate.soundFinished(at: start) == afterHold)
    }

    @Test func resetDropsDuckingWithoutWaitingForCompletions() {
        var gate = DuckingGate()
        _ = gate.soundStarted()
        gate.reset()

        #expect(!gate.isDucking)
        #expect(gate.soundStarted() == .duck)
    }
}
