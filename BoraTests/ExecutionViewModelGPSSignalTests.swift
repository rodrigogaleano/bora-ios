import Foundation
import Testing
@testable import Bora

struct ExecutionViewModelGPSSignalTests {
    private let origin = RouteCoordinate(latitude: 0, longitude: 0)

    private func makeViewModel(clock: PreviewClock, cuePlayer: PreviewRunCuePlayer) -> ExecutionViewModel {
        let plan = SessionPlan(goal: .free, warmup: .duration(3_600), hiit: nil, cooldown: nil)
        return ExecutionViewModel(
            clock: clock,
            locationProvider: PreviewLocationProvider(delay: .zero),
            cuePlayer: cuePlayer,
            runActivity: PreviewRunActivityController(),
            settings: RunSettings(),
            plan: plan,
            route: nil,
            onNext: { _ in }
        )
    }

    private func gpsLostCount(_ cuePlayer: PreviewRunCuePlayer) -> Int {
        cuePlayer.playedCues.filter { $0 == .gpsLost }.count
    }

    private func gpsRecoveredCount(_ cuePlayer: PreviewRunCuePlayer) -> Int {
        cuePlayer.playedCues.filter { $0 == .gpsRecovered }.count
    }

    @Test func noFixForFifteenSecondsFromTheStartFlagsSignalLostOnce() {
        let clock = PreviewClock()
        let cuePlayer = PreviewRunCuePlayer()
        let viewModel = makeViewModel(clock: clock, cuePlayer: cuePlayer)
        viewModel.beginTiming()

        clock.advance(by: 15)
        viewModel.tick()
        clock.advance(by: 5)
        viewModel.tick()
        viewModel.tick()

        #expect(viewModel.isGPSSignalLost)
        #expect(gpsLostCount(cuePlayer) == 1)
    }

    @Test func noWarningBeforeTheTimeout() {
        let clock = PreviewClock()
        let cuePlayer = PreviewRunCuePlayer()
        let viewModel = makeViewModel(clock: clock, cuePlayer: cuePlayer)
        viewModel.beginTiming()

        clock.advance(by: 14)
        viewModel.tick()

        #expect(!viewModel.isGPSSignalLost)
        #expect(gpsLostCount(cuePlayer) == 0)
    }

    @Test func aValidFixRestartsTheCountdown() {
        let clock = PreviewClock()
        let cuePlayer = PreviewRunCuePlayer()
        let viewModel = makeViewModel(clock: clock, cuePlayer: cuePlayer)
        viewModel.beginTiming()

        clock.advance(by: 10)
        viewModel.recordLocation(LocationSample(coordinate: origin))
        clock.advance(by: 10)
        viewModel.tick()

        #expect(!viewModel.isGPSSignalLost)
    }

    @Test func aRejectedFixDoesNotCountAsSignal() {
        let clock = PreviewClock()
        let cuePlayer = PreviewRunCuePlayer()
        let viewModel = makeViewModel(clock: clock, cuePlayer: cuePlayer)
        viewModel.beginTiming()

        clock.advance(by: 10)
        viewModel.recordLocation(LocationSample(coordinate: origin, horizontalAccuracy: 500))
        clock.advance(by: 5)
        viewModel.tick()

        #expect(viewModel.isGPSSignalLost)
    }

    @Test func aValidFixAfterALossClearsItAndAnnouncesRecoveryOnce() {
        let clock = PreviewClock()
        let cuePlayer = PreviewRunCuePlayer()
        let viewModel = makeViewModel(clock: clock, cuePlayer: cuePlayer)
        viewModel.beginTiming()
        clock.advance(by: 20)
        viewModel.tick()

        viewModel.recordLocation(LocationSample(coordinate: origin))
        viewModel.recordLocation(LocationSample(coordinate: origin))

        #expect(!viewModel.isGPSSignalLost)
        #expect(gpsRecoveredCount(cuePlayer) == 1)
    }

    @Test func timePausedDoesNotCountAsSignalLoss() {
        let clock = PreviewClock()
        let cuePlayer = PreviewRunCuePlayer()
        let viewModel = makeViewModel(clock: clock, cuePlayer: cuePlayer)
        viewModel.beginTiming()

        viewModel.pause()
        clock.advance(by: 120)
        viewModel.resume()
        viewModel.tick()

        #expect(!viewModel.isGPSSignalLost)

        clock.advance(by: 15)
        viewModel.tick()

        #expect(viewModel.isGPSSignalLost)
    }
}
