import Testing
@testable import Bora

struct RouteViewModelTests {
    private let plan = SessionPlan(goal: .free, warmup: nil, hiit: nil, cooldown: nil)

    private func makeViewModel(
        error: Error? = nil,
        onNext: @escaping (SessionPlan, PlannedRoute) -> Void = { _, _ in }
    ) -> RouteViewModel {
        RouteViewModel(
            clock: SystemClock(),
            locationProvider: PreviewLocationProvider(delay: .zero, error: error),
            plan: plan,
            onNext: onNext
        )
    }

    @Test func requestInitialLocationSetsStartAndReadyStateOnSuccess() async {
        let viewModel = makeViewModel()
        await viewModel.requestInitialLocation()
        #expect(viewModel.start != nil)
        #expect(viewModel.loadingState == .ready)
    }

    private struct SampleError: Error {}

    @Test func requestInitialLocationSetsFailedStateOnError() async {
        let viewModel = makeViewModel(error: SampleError())
        await viewModel.requestInitialLocation()
        #expect(viewModel.loadingState == .failed)
        #expect(viewModel.start == nil)
    }

    @Test func addPointIsIgnoredBeforeLocationIsReady() {
        let viewModel = makeViewModel()
        viewModel.addPoint(RouteCoordinate(latitude: 0, longitude: 0))
        #expect(viewModel.outboundPoints.isEmpty)
    }

    @Test func addPointAppendsAfterReady() async {
        let viewModel = makeViewModel()
        await viewModel.requestInitialLocation()
        viewModel.addPoint(RouteCoordinate(latitude: 0, longitude: 0.001))
        #expect(viewModel.outboundPoints.count == 1)
    }

    @Test func redoClearsOutboundPointsButKeepsStart() async {
        let viewModel = makeViewModel()
        await viewModel.requestInitialLocation()
        viewModel.addPoint(RouteCoordinate(latitude: 0, longitude: 0.001))
        viewModel.addPoint(RouteCoordinate(latitude: 0, longitude: 0.002))
        viewModel.redo()
        #expect(viewModel.outboundPoints.isEmpty)
        #expect(viewModel.start != nil)
    }

    @Test func isValidFalseWithOnlyStart() async {
        let viewModel = makeViewModel()
        await viewModel.requestInitialLocation()
        #expect(!viewModel.isValid)
    }

    @Test func isValidTrueWithOneOutboundPoint() async {
        let viewModel = makeViewModel()
        await viewModel.requestInitialLocation()
        viewModel.addPoint(RouteCoordinate(latitude: 0, longitude: 0.001))
        #expect(viewModel.isValid)
    }

    @Test func nextForwardsPlanAndRouteWhenValid() async {
        var forwardedPlan: SessionPlan?
        var forwardedRoute: PlannedRoute?
        let viewModel = makeViewModel { plan, route in
            forwardedPlan = plan
            forwardedRoute = route
        }
        await viewModel.requestInitialLocation()
        viewModel.addPoint(RouteCoordinate(latitude: 0, longitude: 0.001))
        viewModel.next()
        #expect(forwardedPlan != nil)
        #expect(forwardedRoute != nil)
    }

    @Test func nextDoesNothingWhenInvalid() async {
        var wasCalled = false
        let viewModel = makeViewModel { _, _ in wasCalled = true }
        await viewModel.requestInitialLocation()
        viewModel.next()
        #expect(!wasCalled)
    }
}
