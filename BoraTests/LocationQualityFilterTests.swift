import Testing
@testable import Bora

struct LocationQualityFilterTests {
    private let origin = RouteCoordinate(latitude: 0, longitude: 0)
    /// ~0.0001 degrees of longitude at the equator is roughly 11 meters.
    private let elevenMetersEast = RouteCoordinate(latitude: 0, longitude: 0.0001)
    /// ~0.001 degrees is roughly 111 meters.
    private let oneHundredElevenMetersEast = RouteCoordinate(latitude: 0, longitude: 0.001)

    private func sample(_ coordinate: RouteCoordinate, accuracy: Double = 5) -> LocationSample {
        LocationSample(coordinate: coordinate, horizontalAccuracy: accuracy)
    }

    @Test func firstGoodFixIsAccepted() {
        #expect(LocationQualityFilter.accepts(sample(origin), after: nil, elapsed: 0, accuracy: .balanced))
    }

    @Test func negativeAccuracyMeansNoFixAndIsRejected() {
        let fix = sample(origin, accuracy: -1)

        #expect(!LocationQualityFilter.accepts(fix, after: nil, elapsed: 0, accuracy: .economy))
    }

    @Test func rejectionThresholdFollowsTheAccuracyLevel() {
        let fifteenMeters = sample(origin, accuracy: 15)
        let thirtyMeters = sample(origin, accuracy: 30)

        #expect(!LocationQualityFilter.accepts(fifteenMeters, after: nil, elapsed: 0, accuracy: .high))
        #expect(LocationQualityFilter.accepts(fifteenMeters, after: nil, elapsed: 0, accuracy: .balanced))
        #expect(!LocationQualityFilter.accepts(thirtyMeters, after: nil, elapsed: 0, accuracy: .balanced))
        #expect(LocationQualityFilter.accepts(thirtyMeters, after: nil, elapsed: 0, accuracy: .economy))
    }

    @Test func accuracyExactlyAtTheLimitIsAccepted() {
        for level in GPSAccuracy.allCases {
            let fix = sample(origin, accuracy: level.maximumHorizontalAccuracy)

            #expect(LocationQualityFilter.accepts(fix, after: nil, elapsed: 0, accuracy: level))
        }
    }

    @Test func plausibleSpeedIsAccepted() {
        // 11 m in 5 s is 2.2 m/s.
        let fix = sample(elevenMetersEast)

        #expect(LocationQualityFilter.accepts(fix, after: origin, elapsed: 5, accuracy: .balanced))
    }

    @Test func impossibleSpeedIsRejectedAsAGpsJump() {
        // 111 m in 2 s is 55 m/s.
        let fix = sample(oneHundredElevenMetersEast)

        #expect(!LocationQualityFilter.accepts(fix, after: origin, elapsed: 2, accuracy: .balanced))
    }

    @Test func speedCannotBeJudgedWithoutElapsedTimeSoTheFixIsKept() {
        let fix = sample(oneHundredElevenMetersEast)

        #expect(LocationQualityFilter.accepts(fix, after: origin, elapsed: 0, accuracy: .balanced))
    }
}
