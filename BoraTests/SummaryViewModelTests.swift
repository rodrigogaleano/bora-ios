import Testing
@testable import Bora

struct SummaryViewModelTests {
    private let route = PlannedRoute(
        start: RouteCoordinate(latitude: 0, longitude: 0),
        outboundPoints: [RouteCoordinate(latitude: 0, longitude: 0.01)]
    )

    private func makeViewModel(
        goal: SessionGoal = .free,
        warmup: BlockTarget? = nil,
        hiit: HIITPlan? = nil,
        cooldown: BlockTarget? = nil,
        route: PlannedRoute? = nil,
        onStart: @escaping (SessionPlan, PlannedRoute?) -> Void = { _, _ in }
    ) -> SummaryViewModel {
        SummaryViewModel(
            plan: SessionPlan(goal: goal, warmup: warmup, hiit: hiit, cooldown: cooldown),
            route: route,
            onStart: onStart
        )
    }

    @Test func titleSaysWhetherThePlanHasIntervals() {
        let intervals = makeViewModel(
            goal: .distance(meters: 5000, scope: .runOnly),
            hiit: HIITPlan(sets: 4, work: .duration(30), rest: .duration(30))
        )
        let continuous = makeViewModel(goal: .distance(meters: 5000, scope: .runOnly))

        #expect(intervals.title.contains("intervals"))
        #expect(continuous.title.contains("continuous"))
    }

    @Test func freeGoalIsOpenEnded() {
        let viewModel = makeViewModel(goal: .free, warmup: .duration(300))

        #expect(viewModel.subtitle.contains("Open-ended"))
        #expect(viewModel.blockRows.last?.trailing == "—")
    }

    @Test func boundedPlanShowsAnEstimate() {
        let viewModel = makeViewModel(goal: .time(1800))

        #expect(viewModel.subtitle.contains("Estimated"))
    }

    @Test func intervalsCollapseIntoASingleRow() {
        let viewModel = makeViewModel(
            warmup: .duration(300),
            hiit: HIITPlan(sets: 4, work: .duration(30), rest: .duration(30)),
            cooldown: .duration(300)
        )

        // Warmup, one row for the whole ladder, cooldown — not eight work/rest lines.
        #expect(viewModel.blockRows.count == 3)
        #expect(viewModel.blockRows[1].badge == "4×")
        #expect(viewModel.blockRows[1].detail != nil)
    }

    @Test func planWithoutIntervalsShowsASingleRunRow() {
        let viewModel = makeViewModel(goal: .distance(meters: 5000, scope: .runOnly))

        #expect(viewModel.blockRows.count == 1)
        #expect(viewModel.blockRows[0].title == RunPhase.Kind.freeRun.displayName)
        #expect(viewModel.blockRows[0].detail == nil)
    }

    @Test func goalNoteExplainsDistanceScopeOnly() {
        let runOnly = makeViewModel(goal: .distance(meters: 5000, scope: .runOnly))
        let totalSession = makeViewModel(goal: .distance(meters: 5000, scope: .totalSession))

        #expect(runOnly.goalNote?.title.contains("run only") == true)
        #expect(totalSession.goalNote?.title.contains("whole session") == true)
        #expect(makeViewModel(goal: .time(1800)).goalNote == nil)
        #expect(makeViewModel(goal: .free).goalNote == nil)
    }

    @Test func goalNoteSaysTheGoalIsOnlyAReferenceWithIntervals() {
        let viewModel = makeViewModel(
            goal: .distance(meters: 5000, scope: .totalSession),
            hiit: HIITPlan(sets: 4, work: .duration(30), rest: .duration(30))
        )

        #expect(viewModel.goalNote?.detail.contains("reference") == true)
    }

    @Test func routeSummaryReportsWhetherARouteExists() {
        #expect(makeViewModel().routeSummary.contains("No route"))
        #expect(makeViewModel(route: route).routeSummary.contains("Out and back"))
    }

    @Test func routeChosenUpdatesTheSummary() {
        let viewModel = makeViewModel()

        viewModel.routeChosen(route)

        #expect(viewModel.route == route)
        #expect(viewModel.routeSummary.contains("Out and back"))
    }

    @Test func startForwardsThePlanAndTheChosenRoute() {
        var forwardedPlan: SessionPlan?
        var forwardedRoute: PlannedRoute?
        let viewModel = makeViewModel(goal: .time(1800)) { plan, route in
            forwardedPlan = plan
            forwardedRoute = route
        }

        viewModel.routeChosen(route)
        viewModel.start()

        #expect(forwardedPlan?.goal == .time(1800))
        #expect(forwardedRoute == route)
    }

    @Test func startWorksWithoutARoute() {
        var didStart = false
        var forwardedRoute: PlannedRoute?
        let viewModel = makeViewModel { _, route in
            didStart = true
            forwardedRoute = route
        }

        viewModel.start()

        #expect(didStart)
        #expect(forwardedRoute == nil)
    }
}
