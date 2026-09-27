import Testing
@testable import Bora

struct PhasePacerTests {
    @Test func lostSignalSpeaksNoPace() {
        #expect(PhasePacer.pace(seconds: 300, meters: 1_000, isSignalLost: true) == nil)
        #expect(PhasePacer.pace(seconds: 300, meters: 1_000, isSignalLost: false) == 300)
    }

    @Test func recoveryBlocksHaveNoRecap() {
        let rest = RunPhase.rest(setIndex: 0, target: .duration(60))

        #expect(PhasePacer.recap(for: rest, elapsed: 60, meters: 200, isSignalLost: false) == nil)
    }

    @Test func eachKilometerStartsFromTheLastMark() {
        var pacer = PhasePacer()

        let first = pacer.pacing(.kilometerSplit(1), elapsed: 300, meters: 1_000, isSignalLost: false)
        let second = pacer.pacing(.kilometerSplit(2), elapsed: 660, meters: 2_000, isSignalLost: false)

        #expect(first == .kilometerSplit(1, pace: 300))
        #expect(second == .kilometerSplit(2, pace: 360))
    }
}
