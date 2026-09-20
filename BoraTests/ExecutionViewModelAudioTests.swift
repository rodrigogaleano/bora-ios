import Foundation
import Testing
@testable import Bora

struct ExecutionViewModelAudioTests {
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

    @Test func audioIsAvailableByDefault() {
        let clock = PreviewClock()
        let viewModel = makeViewModel(clock: clock, cuePlayer: PreviewRunCuePlayer())
        viewModel.beginTiming()

        clock.advance(by: 1)
        viewModel.tick()

        #expect(!viewModel.isAudioUnavailable)
    }

    @Test func unavailableAudioShowsTheWarningOnTheNextTick() {
        let clock = PreviewClock()
        let cuePlayer = PreviewRunCuePlayer()
        let viewModel = makeViewModel(clock: clock, cuePlayer: cuePlayer)
        viewModel.beginTiming()

        cuePlayer.isAudioAvailable = false
        clock.advance(by: 1)
        viewModel.tick()

        #expect(viewModel.isAudioUnavailable)
    }

    @Test func theWarningClearsWhenAudioComesBack() {
        let clock = PreviewClock()
        let cuePlayer = PreviewRunCuePlayer()
        let viewModel = makeViewModel(clock: clock, cuePlayer: cuePlayer)
        viewModel.beginTiming()
        cuePlayer.isAudioAvailable = false
        clock.advance(by: 1)
        viewModel.tick()

        cuePlayer.isAudioAvailable = true
        clock.advance(by: 1)
        viewModel.tick()

        #expect(!viewModel.isAudioUnavailable)
    }
}
