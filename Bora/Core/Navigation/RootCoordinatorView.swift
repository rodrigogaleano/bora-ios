import SwiftUI

struct RootCoordinatorView: View {
    @State private var coordinator: AppCoordinator
    private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _coordinator = State(wrappedValue: AppCoordinator())
    }

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            PlanningView(
                viewModel: PlanningViewModel(
                    clock: dependencies.clock,
                    onNext: { coordinator.push(.route) }
                )
            )
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .route:
                    RouteView(
                        viewModel: RouteViewModel(
                            clock: dependencies.clock,
                            onNext: { coordinator.push(.execution) }
                        )
                    )
                case .execution:
                    ExecutionView(
                        viewModel: ExecutionViewModel(
                            clock: dependencies.clock,
                            onNext: { coordinator.push(.results) }
                        )
                    )
                case .results:
                    ResultsView(
                        viewModel: ResultsViewModel(
                            clock: dependencies.clock,
                            onDone: { coordinator.popToRoot() }
                        )
                    )
                }
            }
        }
        .environment(\.appDependencies, dependencies)
    }
}
