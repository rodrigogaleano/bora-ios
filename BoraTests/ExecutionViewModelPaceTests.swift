import Foundation
import Testing
@testable import Bora

struct ExecutionViewModelPaceTests {
    private static let metersPerDegree = 111_319.49

    private final class Runner {
        let clock = PreviewClock()
        let cuePlayer = PreviewRunCuePlayer()
        let viewModel: ExecutionViewModel
        private var longitude = 0.0

        init(plan: SessionPlan) {
            viewModel = ExecutionViewModel(
                clock: clock,
                locationProvider: PreviewLocationProvider(delay: .zero),
                cuePlayer: cuePlayer,
                runActivity: PreviewRunActivityController(),
                settings: RunSettings(),
                plan: plan,
                route: nil,
                onNext: { _ in }
            )
            viewModel.beginTiming()
            viewModel.recordLocation(LocationSample(coordinate: RouteCoordinate(latitude: 0, longitude: 0)))
        }

        func run(meters: Double, seconds: TimeInterval, steps: Int) {
            for _ in 0..<steps {
                clock.advance(by: seconds)
                longitude += meters / ExecutionViewModelPaceTests.metersPerDegree
                viewModel.recordLocation(LocationSample(coordinate: RouteCoordinate(latitude: 0, longitude: longitude)))
                viewModel.tick()
            }
        }

        func wait(seconds: TimeInterval) {
            clock.advance(by: seconds)
            viewModel.tick()
        }

        var recaps: [RepRecap] {
            cuePlayer.playedCues.compactMap { cue in
                if case .phaseStarted(_, let recap?) = cue {
                    return recap
                }
                return nil
            }
        }

        var kilometerPaces: [Double?] {
            cuePlayer.playedCues.compactMap { cue in
                if case .kilometerSplit(_, let pace) = cue {
                    return .some(pace)
                }
                return nil
            }
        }
    }

    private func intervals(work: BlockTarget, rest: BlockTarget = .duration(60)) -> SessionPlan {
        SessionPlan(goal: .free, warmup: nil, hiit: HIITPlan(sets: 2, work: work, rest: rest), cooldown: nil)
    }

    @Test func distanceRepSpeaksItsTimeWhenTheRestStarts() throws {
        let runner = Runner(plan: intervals(work: .distance(meters: 400)))

        runner.run(meters: 105, seconds: 25, steps: 4)

        let recap = try #require(runner.recaps.first)
        #expect(runner.viewModel.currentPhase?.kind == .rest(setIndex: 0))
        #expect(recap.measure == .time(100))
        let pace = try #require(recap.paceSecondsPerKm)
        #expect(abs(pace - 100 / 0.42) < 1)
    }

    @Test func timedRepSpeaksItsDistance() throws {
        let runner = Runner(plan: intervals(work: .duration(60)))

        runner.run(meters: 100, seconds: 20, steps: 3)

        let recap = try #require(runner.recaps.first)
        guard case .distance(let meters) = recap.measure else {
            Issue.record("Expected the distance covered")
            return
        }
        #expect(abs(meters - 300) < 1)
    }

    @Test func restBlocksHaveNoSummary() {
        let runner = Runner(plan: intervals(work: .duration(60), rest: .duration(30)))

        runner.run(meters: 100, seconds: 20, steps: 3)
        runner.wait(seconds: 30)

        #expect(runner.recaps.count == 1)
        #expect(runner.cuePlayer.playedCues.last == .phaseStarted("Work 2"))
    }

    @Test func repSummaryCanBeTurnedOff() {
        var plan = intervals(work: .duration(60))
        plan.checkpoints.isRepSummaryEnabled = false
        let runner = Runner(plan: plan)

        runner.run(meters: 100, seconds: 20, steps: 3)

        #expect(runner.recaps.isEmpty)
    }

    @Test func shortRepSpeaksNoPace() throws {
        let runner = Runner(plan: intervals(work: .duration(30)))

        runner.run(meters: 40, seconds: 15, steps: 2)

        let recap = try #require(runner.recaps.first)
        #expect(recap.paceSecondsPerKm == nil)
    }

    @Test func pauseIsLeftOutOfTheRepTime() throws {
        let runner = Runner(plan: intervals(work: .distance(meters: 400)))

        runner.run(meters: 105, seconds: 25, steps: 2)
        runner.viewModel.pause()
        runner.clock.advance(by: 100)
        runner.viewModel.resume()
        runner.run(meters: 105, seconds: 25, steps: 2)

        let recap = try #require(runner.recaps.first)
        #expect(recap.measure == .time(100))
    }

    @Test func kilometerPaceCountsOnlyThatKilometer() throws {
        var plan = SessionPlan(goal: .free, warmup: nil, hiit: nil, cooldown: nil)
        plan.checkpoints.isKilometerSplitEnabled = true
        let runner = Runner(plan: plan)

        runner.run(meters: 110, seconds: 20, steps: 10)
        runner.run(meters: 110, seconds: 30, steps: 9)

        let paces = runner.kilometerPaces
        #expect(paces.count == 2)
        let first = try #require(paces[0])
        let second = try #require(paces[1])
        #expect(abs(first - 200 / 1.1) < 1)
        #expect(abs(second - 270 / 0.99) < 1)
    }

    @Test func intervalRunEndsWithTheRepsAverage() throws {
        let plan = SessionPlan(
            goal: .free,
            warmup: nil,
            hiit: HIITPlan(sets: 1, work: .distance(meters: 400), rest: .duration(10)),
            cooldown: nil
        )
        let runner = Runner(plan: plan)

        runner.run(meters: 105, seconds: 25, steps: 4)
        runner.wait(seconds: 10)

        guard case .runFinished(_, let pace?) = runner.cuePlayer.playedCues.last else {
            Issue.record("Expected the final pace")
            return
        }
        #expect(pace.isRepsOnly)
        #expect(abs(pace.secondsPerKm - 100 / 0.42) < 1)
    }
}
