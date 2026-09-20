import Foundation
import Testing
@testable import Bora

struct ExecutionViewModelLocationFilterTests {
    private func makeViewModel(
        plan: SessionPlan,
        clock: PreviewClock,
        settings: RunSettings = RunSettings(),
        onNext: @escaping (SessionMetrics) -> Void = { _ in }
    ) -> ExecutionViewModel {
        ExecutionViewModel(
            clock: clock,
            locationProvider: PreviewLocationProvider(delay: .zero),
            cuePlayer: PreviewRunCuePlayer(),
            runActivity: PreviewRunActivityController(),
            settings: settings,
            plan: plan,
            route: nil,
            onNext: onNext
        )
    }

    @Test func fixWorseThanTheAccuracyLimitDoesNotCount() {
        let clock = PreviewClock()
        let plan = SessionPlan(goal: .free, warmup: .duration(600), hiit: nil, cooldown: nil)
        let viewModel = makeViewModel(plan: plan, clock: clock, settings: RunSettings(gpsAccuracy: .high))
        viewModel.beginTiming()

        viewModel.recordLocation(LocationSample(coordinate: RouteCoordinate(latitude: 0, longitude: 0)))
        clock.advance(by: 10)
        viewModel.recordLocation(
            LocationSample(coordinate: RouteCoordinate(latitude: 0, longitude: 0.0001), horizontalAccuracy: 40)
        )

        #expect(viewModel.totalDistanceMeters == 0)
        #expect(viewModel.traveledPath.count == 1)
    }

    @Test func gpsJumpDoesNotInflateDistanceOrBestSpeed() {
        let clock = PreviewClock()
        let plan = SessionPlan(goal: .free, warmup: .duration(600), hiit: nil, cooldown: nil)
        let viewModel = makeViewModel(plan: plan, clock: clock)
        viewModel.beginTiming()

        viewModel.recordLocation(LocationSample(coordinate: RouteCoordinate(latitude: 0, longitude: 0)))
        clock.advance(by: 2)
        // ~111 m in 2 s is 55 m/s — not a person.
        viewModel.recordLocation(LocationSample(coordinate: RouteCoordinate(latitude: 0, longitude: 0.001)))

        #expect(viewModel.totalDistanceMeters == 0)
        #expect(viewModel.maxSpeedMetersPerSecond == 0)
    }

    @Test func rejectedFixDoesNotAdvanceADistanceGatedPhase() {
        let clock = PreviewClock()
        let plan = SessionPlan(goal: .distance(meters: 100, scope: .runOnly), warmup: nil, hiit: nil, cooldown: nil)
        var finishedMetrics: SessionMetrics?
        let viewModel = makeViewModel(plan: plan, clock: clock, onNext: { finishedMetrics = $0 })
        viewModel.beginTiming()

        viewModel.recordLocation(LocationSample(coordinate: RouteCoordinate(latitude: 0, longitude: 0)))
        viewModel.recordLocation(
            LocationSample(coordinate: RouteCoordinate(latitude: 0, longitude: 0.001), horizontalAccuracy: 200)
        )
        viewModel.tick()

        #expect(finishedMetrics == nil)
    }
}
