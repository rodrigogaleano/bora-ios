import Testing
@testable import Bora

struct RouteViewModelTests {
    private func makeViewModel(
        error: Error? = nil,
        existingRoute: PlannedRoute? = nil,
        onDone: @escaping (PlannedRoute) -> Void = { _ in }
    ) -> RouteViewModel {
        RouteViewModel(
            locationProvider: PreviewLocationProvider(delay: .zero, error: error),
            existingRoute: existingRoute,
            onDone: onDone
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

    @Test func nextForwardsTheRouteWhenValid() async {
        var forwardedRoute: PlannedRoute?
        let viewModel = makeViewModel { route in forwardedRoute = route }
        await viewModel.requestInitialLocation()
        viewModel.addPoint(RouteCoordinate(latitude: 0, longitude: 0.001))
        viewModel.next()
        #expect(forwardedRoute?.outboundPoints.count == 1)
    }

    @Test func nextDoesNothingWhenInvalid() async {
        var wasCalled = false
        let viewModel = makeViewModel { _ in wasCalled = true }
        await viewModel.requestInitialLocation()
        viewModel.next()
        #expect(!wasCalled)
    }

    @Test func existingRouteIsRestoredWithoutAskingForLocationAgain() async {
        let existing = PlannedRoute(
            start: RouteCoordinate(latitude: 10, longitude: 10),
            outboundPoints: [RouteCoordinate(latitude: 10, longitude: 10.001)]
        )
        let viewModel = makeViewModel(error: SampleError(), existingRoute: existing)

        #expect(viewModel.loadingState == .ready)

        // The provider would fail, but a restored route must not be thrown away for a new fix.
        await viewModel.requestInitialLocation()

        #expect(viewModel.loadingState == .ready)
        #expect(viewModel.start == existing.start)
        #expect(viewModel.outboundPoints == existing.outboundPoints)
    }
}
