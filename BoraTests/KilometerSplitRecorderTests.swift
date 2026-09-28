import Testing
@testable import Bora

struct KilometerSplitRecorderTests {
    @Test func completedKilometersKeepTheirOwnTime() {
        var recorder = KilometerSplitRecorder()
        recorder.record(totalMeters: 999, elapsed: 290)
        recorder.record(totalMeters: 1_000, elapsed: 300)
        recorder.record(totalMeters: 2_010, elapsed: 620)

        let splits = recorder.splits(totalMeters: 2_500, elapsed: 780)

        #expect(splits.map(\.distanceMeters) == [1_000, 1_000, 500])
        #expect(splits.map(\.duration) == [300, 320, 160])
    }

    @Test func shortRemainderIsLeftOut() {
        var recorder = KilometerSplitRecorder()
        recorder.record(totalMeters: 1_000, elapsed: 300)

        #expect(recorder.splits(totalMeters: 1_080, elapsed: 330).count == 1)
    }

    @Test func gpsJumpAcrossTwoKilometersSplitsTheTime() {
        var recorder = KilometerSplitRecorder()
        recorder.record(totalMeters: 2_000, elapsed: 600)

        let splits = recorder.splits(totalMeters: 2_000, elapsed: 600)

        #expect(splits.map(\.duration) == [300, 300])
    }

    @Test func noDistanceHasNoSplits() {
        #expect(KilometerSplitRecorder().splits(totalMeters: 0, elapsed: 600).isEmpty)
    }
}
