import Testing
@testable import Bora

struct CountdownViewModelTests {
    private let plan = SessionPlan(goal: .free, warmup: nil, hiit: nil, cooldown: nil)
    private let route = PlannedRoute(start: RouteCoordinate(latitude: 0, longitude: 0), outboundPoints: [])

    private func makeViewModel(
        onFinished: @escaping (SessionPlan, PlannedRoute) -> Void = { _, _ in },
        onCancel: @escaping () -> Void = {}
    ) -> CountdownViewModel {
        CountdownViewModel(plan: plan, route: route, startingFrom: 3, onFinished: onFinished, onCancel: onCancel)
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

    @Test func cancelInvokesOnCancel() {
        var wasCancelled = false
        let viewModel = makeViewModel(onCancel: { wasCancelled = true })
        viewModel.cancel()
        #expect(wasCancelled)
    }
}
