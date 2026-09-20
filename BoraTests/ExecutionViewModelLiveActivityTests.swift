import Foundation
import Testing
@testable import Bora

struct ExecutionViewModelLiveActivityTests {
    private func makeViewModel(
        plan: SessionPlan,
        clock: PreviewClock,
        runActivity: RunActivityProviding
    ) -> ExecutionViewModel {
        ExecutionViewModel(
            clock: clock,
            locationProvider: PreviewLocationProvider(delay: .zero),
            cuePlayer: PreviewRunCuePlayer(),
            runActivity: runActivity,
            settings: RunSettings(),
            plan: plan,
            route: nil,
            onNext: { _ in }
        )
    }

    @Test func liveActivityStartsOnceAndFollowsPhaseChanges() {
        let clock = PreviewClock()
        let spy = SpyRunActivityController()
        let plan = SessionPlan(goal: .free, warmup: .duration(10), hiit: nil, cooldown: .duration(10))
        let viewModel = makeViewModel(plan: plan, clock: clock, runActivity: spy)
        viewModel.beginTiming()
        #expect(spy.startedStates.count == 1)
        #expect(spy.startedStates.first?.phaseTitle == RunPhase.Kind.warmup.displayName)
        #expect(spy.startedStates.first?.phaseCount == 3)

        clock.advance(by: 10)
        viewModel.tick()
        #expect(spy.updatedStates.last?.phaseTitle == RunPhase.Kind.freeRun.displayName)
        #expect(spy.updatedStates.last?.phaseNumber == 2)
    }

    @Test func liveActivityHoldsUpdatesBetweenPublishIntervals() {
        let clock = PreviewClock()
        let spy = SpyRunActivityController()
        let plan = SessionPlan(goal: .free, warmup: .duration(600), hiit: nil, cooldown: nil)
        let viewModel = makeViewModel(plan: plan, clock: clock, runActivity: spy)
        viewModel.beginTiming()
        clock.advance(by: 1)
        viewModel.tick()
        #expect(spy.updatedStates.isEmpty)
    }

    @Test func liveActivityPublishesImmediatelyOnPause() {
        let spy = SpyRunActivityController()
        let plan = SessionPlan(goal: .free, warmup: .duration(600), hiit: nil, cooldown: nil)
        let viewModel = makeViewModel(plan: plan, clock: PreviewClock(), runActivity: spy)
        viewModel.beginTiming()
        viewModel.pause()
        #expect(spy.updatedStates.count == 1)
        #expect(spy.updatedStates.last?.pausedAt != nil)
    }

    @Test func liveActivityEndsWithSessionTotals() {
        let clock = PreviewClock()
        let spy = SpyRunActivityController()
        let plan = SessionPlan(goal: .free, warmup: .duration(600), hiit: nil, cooldown: nil)
        let viewModel = makeViewModel(plan: plan, clock: clock, runActivity: spy)
        viewModel.beginTiming()
        viewModel.recordLocation(RouteCoordinate(latitude: 0, longitude: 0))
        viewModel.recordLocation(RouteCoordinate(latitude: 0, longitude: 0.001))
        clock.advance(by: 30)
        viewModel.tick()
        viewModel.finish()
        #expect(spy.endedStates.count == 1)
        #expect(spy.endedStates.last?.distanceMeters == viewModel.totalDistanceMeters)
        #expect(spy.endedStates.last?.pausedAt != nil)
    }
}

private final class SpyRunActivityController: RunActivityProviding {
    private(set) var startedStates: [RunActivityAttributes.ContentState] = []
    private(set) var updatedStates: [RunActivityAttributes.ContentState] = []
    private(set) var endedStates: [RunActivityAttributes.ContentState] = []

    func start(planTitle: String, state: RunActivityAttributes.ContentState) {
        startedStates.append(state)
    }

    func update(_ state: RunActivityAttributes.ContentState) {
        updatedStates.append(state)
    }

    func end(_ state: RunActivityAttributes.ContentState) {
        endedStates.append(state)
    }
}
