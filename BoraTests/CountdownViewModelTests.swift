import Testing
@testable import Bora

struct CountdownViewModelTests {
    private let plan = SessionPlan(goal: .free, warmup: nil, hiit: nil, cooldown: nil)
    private let route = PlannedRoute(start: RouteCoordinate(latitude: 0, longitude: 0), outboundPoints: [])

    private func makeViewModel(
        cuePlayer: PreviewRunCuePlayer = PreviewRunCuePlayer(),
        onFinished: @escaping (SessionPlan, PlannedRoute) -> Void = { _, _ in },
        onCancel: @escaping () -> Void = {}
    ) -> CountdownViewModel {
        CountdownViewModel(
            plan: plan,
            route: route,
            cuePlayer: cuePlayer,
            settings: RunSettings(),
            startingFrom: 3,
            onFinished: onFinished,
            onCancel: onCancel
        )
    }

    @Test func tickDecrementsCount() {
        let viewModel = makeViewModel()
        viewModel.tick()
        #expect(viewModel.count == 2)
    }

    @Test func countReachesZeroInvokesOnFinishedWithPlanAndRoute() {
        var forwardedPlan: SessionPlan?
        var forwardedRoute: PlannedRoute?
        let viewModel = makeViewModel(onFinished: { plan, route in
            forwardedPlan = plan
            forwardedRoute = route
        })

        viewModel.tick()
        viewModel.tick()
        #expect(forwardedPlan == nil)

        viewModel.tick()
        #expect(viewModel.count == 0)
        #expect(forwardedPlan == plan)
        #expect(forwardedRoute == route)
    }

    @Test func cancelInvokesOnCancelAndReleasesAudio() {
        let cuePlayer = PreviewRunCuePlayer()
        var wasCancelled = false
        let viewModel = makeViewModel(cuePlayer: cuePlayer, onCancel: { wasCancelled = true })
        viewModel.cancel()
        #expect(wasCancelled)
        #expect(cuePlayer.isTornDown)
    }

    @Test func eachRemainingSecondGetsACue() {
        let cuePlayer = PreviewRunCuePlayer()
        let viewModel = makeViewModel(cuePlayer: cuePlayer)

        viewModel.start()
        viewModel.tick()
        viewModel.tick()
        // Reaching zero hands off to the run instead of ticking again.
        viewModel.tick()

        #expect(cuePlayer.playedCues == [.countdownTick(3), .countdownTick(2), .countdownTick(1)])
    }
}
