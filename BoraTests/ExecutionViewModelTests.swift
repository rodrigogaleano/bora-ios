import Foundation
import Testing
@testable import Bora

struct ExecutionViewModelTests {
    private let route = PlannedRoute(start: RouteCoordinate(latitude: 0, longitude: 0), outboundPoints: [])

    private func makeViewModel(
        plan: SessionPlan,
        clock: PreviewClock = PreviewClock(),
        onNext: @escaping (SessionMetrics) -> Void = { _ in }
    ) -> ExecutionViewModel {
        ExecutionViewModel(
            clock: clock,
            locationProvider: PreviewLocationProvider(delay: .zero),
            plan: plan,
            route: route,
            onNext: onNext
        )
    }

    @Test func startInitializesFirstPhaseAsWarmupWhenPresent() {
        let plan = SessionPlan(goal: .free, warmup: .duration(60), hiit: nil, cooldown: nil)
        let viewModel = makeViewModel(plan: plan)
        viewModel.start()
        #expect(viewModel.currentPhase?.kind == .warmup)
    }

    @Test func tickAdvancesElapsedInPhase() {
        let clock = PreviewClock()
        let plan = SessionPlan(goal: .free, warmup: .duration(60), hiit: nil, cooldown: nil)
        let viewModel = makeViewModel(plan: plan, clock: clock)
        viewModel.beginTiming()
        clock.advance(by: 5)
        viewModel.tick()
        #expect(viewModel.elapsedInPhase == 5)
    }

    @Test func phaseAutoAdvancesWhenDurationTargetReached() {
        let clock = PreviewClock()
        let plan = SessionPlan(goal: .free, warmup: .duration(10), hiit: nil, cooldown: .duration(10))
        let viewModel = makeViewModel(plan: plan, clock: clock)
        viewModel.beginTiming()
        clock.advance(by: 10)
        viewModel.tick()
        #expect(viewModel.currentPhaseIndex == 1)
        #expect(viewModel.currentPhase?.kind == .freeRun)
        #expect(viewModel.elapsedInPhase == 0)
    }

    @Test func hiitSequenceCyclesThroughAllSetsThenCooldownThenFinishes() {
        let clock = PreviewClock()
        let plan = SessionPlan(
            goal: .free,
            warmup: nil,
            hiit: HIITPlan(sets: 2, work: .duration(10), rest: .duration(5)),
            cooldown: .duration(10)
        )
        var finishedMetrics: SessionMetrics?
        let viewModel = makeViewModel(plan: plan, clock: clock, onNext: { finishedMetrics = $0 })
        viewModel.beginTiming()

        // work0 -> rest0 -> work1 -> rest1 -> cooldown -> finished
        let durations: [TimeInterval] = [10, 5, 10, 5, 10]
        for duration in durations {
            clock.advance(by: duration)
            viewModel.tick()
        }

        #expect(finishedMetrics != nil)
        #expect(finishedMetrics?.splits.count == 5)
    }

    @Test func pauseFreezesElapsedProgression() {
        let clock = PreviewClock()
        let plan = SessionPlan(goal: .free, warmup: .duration(60), hiit: nil, cooldown: nil)
        let viewModel = makeViewModel(plan: plan, clock: clock)
        viewModel.beginTiming()
        clock.advance(by: 5)
        viewModel.tick()
        #expect(viewModel.elapsedInPhase == 5)

        viewModel.pause()
        clock.advance(by: 10)
        viewModel.tick()
        #expect(viewModel.elapsedInPhase == 5)
        #expect(viewModel.runState == .paused)
    }

    @Test func resumeContinuesElapsedExcludingPausedTime() {
        let clock = PreviewClock()
        let plan = SessionPlan(goal: .free, warmup: .duration(60), hiit: nil, cooldown: nil)
        let viewModel = makeViewModel(plan: plan, clock: clock)
        viewModel.beginTiming()
        clock.advance(by: 5)
        viewModel.tick()

        viewModel.pause()
        clock.advance(by: 100)
        viewModel.resume()

        clock.advance(by: 3)
        viewModel.tick()
        #expect(viewModel.elapsedInPhase == 8)
        #expect(viewModel.elapsedTotal == 8)
    }

    @Test func finishInvokesOnNextWithPopulatedMetrics() {
        let clock = PreviewClock()
        let plan = SessionPlan(goal: .free, warmup: .duration(600), hiit: nil, cooldown: nil)
        var finishedMetrics: SessionMetrics?
        let viewModel = makeViewModel(plan: plan, clock: clock, onNext: { finishedMetrics = $0 })
        viewModel.beginTiming()

        clock.advance(by: 10)
        viewModel.recordLocation(RouteCoordinate(latitude: 0, longitude: 0.001))
        clock.advance(by: 10)
        viewModel.recordLocation(RouteCoordinate(latitude: 0, longitude: 0.002))
        viewModel.tick()

        viewModel.finish()

        #expect(finishedMetrics != nil)
        #expect(finishedMetrics!.totalDistanceMeters > 0)
        #expect(finishedMetrics!.splits.count == 1)
        #expect(viewModel.runState == .finished)
    }

    @Test func freeRunPhaseWithDistanceGoalRunOnlyCompletesWhenDistanceAccumulates() {
        let clock = PreviewClock()
        let plan = SessionPlan(goal: .distance(meters: 100, scope: .runOnly), warmup: nil, hiit: nil, cooldown: nil)
        var finishedMetrics: SessionMetrics?
        let viewModel = makeViewModel(plan: plan, clock: clock, onNext: { finishedMetrics = $0 })
        viewModel.beginTiming()

        viewModel.recordLocation(RouteCoordinate(latitude: 0, longitude: 0))
        // ~0.001 degrees longitude at the equator is roughly 111 meters.
        viewModel.recordLocation(RouteCoordinate(latitude: 0, longitude: 0.001))
        viewModel.tick()

        #expect(finishedMetrics != nil)
    }

    @Test func isShowingUpcomingTransitionBannerTrueWithinTenSecondsOfDurationPhaseEnd() {
        let clock = PreviewClock()
        let plan = SessionPlan(goal: .free, warmup: .duration(15), hiit: nil, cooldown: nil)
        let viewModel = makeViewModel(plan: plan, clock: clock)
        viewModel.beginTiming()

        clock.advance(by: 4)
        viewModel.tick()
        #expect(!viewModel.isShowingUpcomingTransitionBanner)

        clock.advance(by: 2)
        viewModel.tick()
        #expect(viewModel.isShowingUpcomingTransitionBanner)
    }
}
