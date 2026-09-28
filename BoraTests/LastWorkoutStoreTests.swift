import Foundation
import Testing
@testable import Bora

struct LastWorkoutStoreTests {
    private func makeDefaults() -> UserDefaults {
        let suite = "LastWorkoutStoreTests.\(UUID().uuidString)"
        UserDefaults().removePersistentDomain(forName: suite)
        return UserDefaults(suiteName: suite) ?? .standard
    }

    private var intervals: SessionPlan {
        var checkpoints = WorkoutType.intervals.defaultCheckpoints
        checkpoints.progress = [.quarter, .threeQuarters]
        checkpoints.isKilometerSplitEnabled = true
        return SessionPlan(
            goal: .free,
            warmup: .distance(meters: 1_500),
            hiit: HIITPlan(sets: 8, work: .distance(meters: 1_000), rest: .duration(120)),
            cooldown: .duration(600),
            workoutType: .intervals,
            checkpoints: checkpoints
        )
    }

    @Test func emptyStoreReturnsNothing() {
        let store = UserDefaultsLastWorkoutStore(defaults: makeDefaults())

        #expect(store.load(.intervals) == nil)
    }

    @Test func savedPlanRoundTrips() {
        let defaults = makeDefaults()

        UserDefaultsLastWorkoutStore(defaults: defaults).save(intervals)

        #expect(UserDefaultsLastWorkoutStore(defaults: defaults).load(.intervals) == intervals)
    }

    @Test func typesDoNotMix() {
        let store = UserDefaultsLastWorkoutStore(defaults: makeDefaults())
        let longRun = SessionPlan(goal: .distance(meters: 21_000, scope: .runOnly), workoutType: .longRun)

        store.save(intervals)
        store.save(longRun)

        #expect(store.load(.intervals) == intervals)
        #expect(store.load(.longRun) == longRun)
        #expect(store.load(.easyRun) == nil)
    }

    @Test func unreadableBlobReturnsNothing() {
        let defaults = makeDefaults()
        defaults.set(Data("not json".utf8), forKey: UserDefaultsLastWorkoutStore.key(for: .intervals))

        #expect(UserDefaultsLastWorkoutStore(defaults: defaults).load(.intervals) == nil)
    }
}
