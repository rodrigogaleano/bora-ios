import Foundation
import Testing
@testable import Bora

struct ExecutionViewModelCheckpointTests {
    private func makeViewModel(
        plan: SessionPlan,
        clock: PreviewClock,
        cuePlayer: PreviewRunCuePlayer,
        settings: RunSettings = RunSettings()
    ) -> ExecutionViewModel {
        ExecutionViewModel(
            clock: clock,
            locationProvider: PreviewLocationProvider(delay: .zero),
            cuePlayer: cuePlayer,
            runActivity: PreviewRunActivityController(),
            settings: settings,
            plan: plan,
            route: nil,
            onNext: { _ in }
        )
    }

    @Test func distanceBlockAnnouncesTheNextBlockBeforeItEnds() {
        let clock = PreviewClock()
        let cuePlayer = PreviewRunCuePlayer()
        let plan = SessionPlan(
            goal: .free,
            warmup: nil,
            hiit: HIITPlan(sets: 1, work: .distance(meters: 150), rest: .duration(60)),
            cooldown: nil
        )
        let viewModel = makeViewModel(plan: plan, clock: clock, cuePlayer: cuePlayer)
        viewModel.beginTiming()

        viewModel.recordLocation(LocationSample(coordinate: RouteCoordinate(latitude: 0, longitude: 0)))
        clock.advance(by: 30)
        viewModel.recordLocation(LocationSample(coordinate: RouteCoordinate(latitude: 0, longitude: 0.001)))
        viewModel.tick()

        #expect(viewModel.currentPhase?.kind == .work(setIndex: 0))
        #expect(cuePlayer.playedCues.last == .upcomingTransition("Rest 1"))
    }

    @Test func lastBlockAnnouncesTheRunIsEnding() {
        let clock = PreviewClock()
        let cuePlayer = PreviewRunCuePlayer()
        let plan = SessionPlan(goal: .time(60), warmup: nil, hiit: nil, cooldown: nil)
        let viewModel = makeViewModel(plan: plan, clock: clock, cuePlayer: cuePlayer)
        viewModel.beginTiming()

        clock.advance(by: 51)
        viewModel.tick()

        #expect(cuePlayer.playedCues.last == .runEnding)
    }

    @Test func transitionWarningCanBeTurnedOff() {
        let clock = PreviewClock()
        let cuePlayer = PreviewRunCuePlayer()
        var settings = RunSettings()
        settings.isTransitionWarningEnabled = false
        let plan = SessionPlan(goal: .free, warmup: .duration(15), hiit: nil, cooldown: nil)
        let viewModel = makeViewModel(plan: plan, clock: clock, cuePlayer: cuePlayer, settings: settings)
        viewModel.beginTiming()

        clock.advance(by: 8)
        viewModel.tick()

        #expect(cuePlayer.playedCues == [.phaseStarted("Warmup")])
    }

    @Test func workBlockAnnouncesHalfway() {
        let clock = PreviewClock()
        let cuePlayer = PreviewRunCuePlayer()
        let plan = SessionPlan(
            goal: .free,
            warmup: nil,
            hiit: HIITPlan(sets: 1, work: .distance(meters: 1_000), rest: .duration(60)),
            cooldown: nil
        )
        let viewModel = makeViewModel(plan: plan, clock: clock, cuePlayer: cuePlayer)
        viewModel.beginTiming()

        viewModel.recordLocation(LocationSample(coordinate: RouteCoordinate(latitude: 0, longitude: 0)))
        clock.advance(by: 150)
        viewModel.recordLocation(LocationSample(coordinate: RouteCoordinate(latitude: 0, longitude: 0.0046)))
        viewModel.tick()

        guard case .progress(.half, let pace) = cuePlayer.playedCues.last else {
            Issue.record("Expected the halfway cue")
            return
        }
        #expect(pace != nil)
    }
}
