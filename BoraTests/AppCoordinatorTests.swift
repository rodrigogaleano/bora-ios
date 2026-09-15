import SwiftUI
import Testing
@testable import Bora

struct AppCoordinatorTests {
    private let plan = SessionPlan(goal: .free, warmup: nil, hiit: nil, cooldown: nil)
    private let route = PlannedRoute(start: RouteCoordinate(latitude: 0, longitude: 0), outboundPoints: [])

    @Test func pushAppendsRoute() {
        let coordinator = AppCoordinator()
        coordinator.push(.route(plan))
        #expect(coordinator.path.count == 1)
    }

    @Test func popToRootClearsPath() {
        let coordinator = AppCoordinator()
        coordinator.push(.route(plan))
        coordinator.push(.execution(plan, route))
        coordinator.popToRoot()
        #expect(coordinator.path.count == 0)
    }
}
