import Foundation
import Testing
@testable import Bora

struct SessionEstimatorTests {
    private func plan(
        goal: SessionGoal = .free,
        warmup: BlockTarget? = nil,
        hiit: HIITPlan? = nil,
        cooldown: BlockTarget? = nil
    ) -> SessionPlan {
        SessionPlan(goal: goal, warmup: warmup, hiit: hiit, cooldown: cooldown)
    }

    @Test func durationBlockGetsDistanceFromItsPace() {
        let estimate = SessionEstimator.estimate(
            for: plan(goal: .distance(meters: 1000, scope: .runOnly), warmup: .duration(390))
        )

        let warmup = estimate.blocks.first
        #expect(warmup?.kind == .warmup)
        #expect(warmup?.duration == 390)
        // 390 s at the warmup pace of 390 s/km is exactly one kilometre.
        #expect(warmup?.distanceMeters == 1000)
    }

    @Test func distanceBlockGetsDurationFromItsPace() {
        let estimate = SessionEstimator.estimate(
            for: plan(goal: .distance(meters: 1000, scope: .runOnly), cooldown: .distance(meters: 500))
        )

        let cooldown = estimate.blocks.last
        #expect(cooldown?.kind == .cooldown)
        #expect(cooldown?.distanceMeters == 500)
        #expect(cooldown?.duration == SessionEstimator.paceSecondsPerKm(for: .cooldown) / 2)
    }

    @Test func totalsAreTheSumOfEveryBlock() {
        let estimate = SessionEstimator.estimate(
            for: plan(
                goal: .distance(meters: 2000, scope: .runOnly),
                warmup: .duration(300),
                cooldown: .duration(300)
            )
        )

        #expect(estimate.blocks.count == 3)
        #expect(estimate.duration == estimate.blocks.reduce(0) { $0 + $1.duration })
        #expect(estimate.totalDistanceMeters == estimate.blocks.reduce(0) { $0 + $1.distanceMeters })
    }

    @Test func runDistanceExcludesWarmupRestAndCooldown() {
        let estimate = SessionEstimator.estimate(
            for: plan(
                warmup: .duration(300),
                hiit: HIITPlan(sets: 2, work: .distance(meters: 400), rest: .duration(60)),
                cooldown: .duration(300)
            )
        )

        #expect(estimate.runDistanceMeters == 800)
        #expect(estimate.totalDistanceMeters > estimate.runDistanceMeters)
        #expect(!estimate.isOpenEnded)
    }

    @Test func totalSessionGoalSubtractsTheOtherBlocks() {
        let warmup = BlockTarget.distance(meters: 1000)
        let cooldown = BlockTarget.distance(meters: 500)
        let estimate = SessionEstimator.estimate(
            for: plan(goal: .distance(meters: 5000, scope: .totalSession), warmup: warmup, cooldown: cooldown)
        )

        #expect(estimate.runDistanceMeters == 3500)
        #expect(estimate.totalDistanceMeters == 5000)
    }

    @Test func runOnlyGoalIgnoresTheOtherBlocks() {
        let estimate = SessionEstimator.estimate(
            for: plan(
                goal: .distance(meters: 5000, scope: .runOnly),
                warmup: .distance(meters: 1000),
                cooldown: .distance(meters: 500)
            )
        )

        #expect(estimate.runDistanceMeters == 5000)
        #expect(estimate.totalDistanceMeters == 6500)
    }

    @Test func goalSwallowedByTheOtherBlocksStillLeavesARunBlock() {
        let estimate = SessionEstimator.estimate(
            for: plan(
                goal: .distance(meters: 1000, scope: .totalSession),
                warmup: .distance(meters: 800),
                cooldown: .distance(meters: 800)
            )
        )

        #expect(estimate.runDistanceMeters == 400)
    }

    @Test func timeGoalSubtractsTheOtherBlocksFromTheRunBlock() {
        let estimate = SessionEstimator.estimate(
            for: plan(goal: .time(1800), warmup: .duration(300), cooldown: .duration(300))
        )

        let freeRun = estimate.blocks.first { $0.kind == .freeRun }
        #expect(freeRun?.duration == 1200)
        #expect(estimate.duration == 1800)
    }

    @Test func freeGoalWithoutIntervalsIsOpenEnded() {
        let estimate = SessionEstimator.estimate(for: plan(goal: .free, warmup: .duration(300)))

        #expect(estimate.isOpenEnded)
        // The run block is still listed, it just carries no numbers.
        #expect(estimate.blocks.contains { $0.kind == .freeRun && $0.duration == 0 })
        #expect(estimate.duration == 300)
    }

    @Test func freeGoalWithIntervalsIsNotOpenEnded() {
        let estimate = SessionEstimator.estimate(
            for: plan(goal: .free, hiit: HIITPlan(sets: 3, work: .duration(30), rest: .duration(30)))
        )

        #expect(!estimate.isOpenEnded)
        #expect(estimate.duration == 180)
    }
}
