import Foundation
import Testing
@testable import Bora

struct ExecutionViewModelTests {
    private let route = PlannedRoute(start: RouteCoordinate(latitude: 0, longitude: 0), outboundPoints: [])

    private func makeViewModel(
        plan: SessionPlan,
        clock: PreviewClock = PreviewClock(),
        cuePlayer: PreviewRunCuePlayer = PreviewRunCuePlayer(),
        runActivity: RunActivityProviding = PreviewRunActivityController(),
        settings: RunSettings = RunSettings(),
        route: PlannedRoute? = nil,
        onNext: @escaping (SessionMetrics) -> Void = { _ in }
    ) -> ExecutionViewModel {
        ExecutionViewModel(
            clock: clock,
            locationProvider: PreviewLocationProvider(delay: .zero),
            cuePlayer: cuePlayer,
            runActivity: runActivity,
            settings: settings,
            plan: plan,
            route: route ?? self.route,
            onNext: onNext
        )
    }

    @Test func runsWithoutAPlannedRoute() {
        let plan = SessionPlan(goal: .free, warmup: .duration(60), hiit: nil, cooldown: nil)
        let viewModel = ExecutionViewModel(
            clock: PreviewClock(),
            locationProvider: PreviewLocationProvider(delay: .zero),
            cuePlayer: PreviewRunCuePlayer(),
            runActivity: PreviewRunActivityController(),
            settings: RunSettings(),
            plan: plan,
            route: nil,
            onNext: { _ in }
        )
        viewModel.start()
        #expect(viewModel.plannedRoute == nil)
        #expect(viewModel.currentPhase?.kind == .warmup)
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
        viewModel.recordLocation(LocationSample(coordinate: RouteCoordinate(latitude: 0, longitude: 0.001)))
        clock.advance(by: 10)
        viewModel.recordLocation(LocationSample(coordinate: RouteCoordinate(latitude: 0, longitude: 0.002)))
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

        viewModel.recordLocation(LocationSample(coordinate: RouteCoordinate(latitude: 0, longitude: 0)))
        // ~0.001 degrees longitude at the equator is roughly 111 meters.
        viewModel.recordLocation(LocationSample(coordinate: RouteCoordinate(latitude: 0, longitude: 0.001)))
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

    @Test func eachPhaseIsAnnouncedWhenItStarts() {
        let clock = PreviewClock()
        let cuePlayer = PreviewRunCuePlayer()
        let plan = SessionPlan(
            goal: .free,
            warmup: .duration(10),
            hiit: HIITPlan(sets: 1, work: .duration(10), rest: .duration(10)),
            cooldown: nil
        )
        let viewModel = makeViewModel(plan: plan, clock: clock, cuePlayer: cuePlayer)
        viewModel.beginTiming()

        clock.advance(by: 10)
        viewModel.tick()
        clock.advance(by: 10)
        viewModel.tick()

        let announced = cuePlayer.playedCues.compactMap { cue -> String? in
            if case .phaseStarted(let name) = cue { return name }
            return nil
        }
        #expect(announced == ["Warmup", "Work 1", "Rest 1"])
    }

    @Test func upcomingTransitionIsAnnouncedOncePerPhase() {
        let clock = PreviewClock()
        let cuePlayer = PreviewRunCuePlayer()
        let plan = SessionPlan(goal: .free, warmup: .duration(15), hiit: nil, cooldown: .duration(60))
        let viewModel = makeViewModel(plan: plan, clock: clock, cuePlayer: cuePlayer)
        viewModel.beginTiming()

        // Five ticks inside the 10s warning window; only the first should announce.
        clock.advance(by: 6)
        for _ in 0..<5 {
            viewModel.tick()
            clock.advance(by: 0.5)
        }

        let warnings = cuePlayer.playedCues.filter { cue in
            if case .upcomingTransition = cue { return true }
            return false
        }
        #expect(warnings.count == 1)
        #expect(warnings.first == .upcomingTransition("Run"))
    }

    @Test func metronomeStopsWhilePausedAndDuringRest() {
        let clock = PreviewClock()
        let cuePlayer = PreviewRunCuePlayer()
        var settings = RunSettings()
        settings.isMetronomeEnabled = true
        let plan = SessionPlan(
            goal: .free,
            warmup: nil,
            hiit: HIITPlan(sets: 1, work: .duration(10), rest: .duration(10)),
            cooldown: nil
        )
        let viewModel = makeViewModel(plan: plan, clock: clock, cuePlayer: cuePlayer, settings: settings)
        viewModel.beginTiming()
        #expect(cuePlayer.metronomeBPM == settings.metronomeBPM)

        viewModel.pause()
        #expect(!cuePlayer.isMetronomeRunning)
        viewModel.resume()
        #expect(cuePlayer.isMetronomeRunning)

        clock.advance(by: 10)
        viewModel.tick()
        #expect(viewModel.currentPhase?.kind == .rest(setIndex: 0))
        #expect(!cuePlayer.isMetronomeRunning)
    }

    @Test func metronomeStaysSilentWhenDisabled() {
        let cuePlayer = PreviewRunCuePlayer()
        let plan = SessionPlan(goal: .free, warmup: .duration(60), hiit: nil, cooldown: nil)
        let viewModel = makeViewModel(plan: plan, cuePlayer: cuePlayer)

        viewModel.beginTiming()

        #expect(!cuePlayer.isMetronomeRunning)
    }

    @Test func finishAnnouncesTheEndAndReleasesAudio() {
        let cuePlayer = PreviewRunCuePlayer()
        let plan = SessionPlan(goal: .free, warmup: .duration(600), hiit: nil, cooldown: nil)
        let viewModel = makeViewModel(plan: plan, cuePlayer: cuePlayer)
        viewModel.beginTiming()

        viewModel.finish()

        #expect(cuePlayer.playedCues.last == .runFinished)
        #expect(cuePlayer.isTornDown)
    }
}
