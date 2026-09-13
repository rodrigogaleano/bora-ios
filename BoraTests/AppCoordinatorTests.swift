import SwiftUI
import Testing
@testable import Bora

struct AppCoordinatorTests {
    @Test func pushAppendsRoute() {
        let coordinator = AppCoordinator()
        coordinator.push(.route)
        #expect(coordinator.path.count == 1)
    }

    @Test func popToRootClearsPath() {
        let coordinator = AppCoordinator()
        coordinator.push(.route)
        coordinator.push(.execution)
        coordinator.popToRoot()
        #expect(coordinator.path.count == 0)
    }
}
