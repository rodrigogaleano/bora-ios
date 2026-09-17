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
                    onNext: { plan in coordinator.push(.route(plan)) }
                )
            )
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .route(let plan):
                    RouteView(
                        viewModel: RouteViewModel(
                            clock: dependencies.clock,
                            locationProvider: dependencies.locationProvider,
                            plan: plan,
                            onNext: { plan, route in coordinator.push(.countdown(plan, route)) }
                        )
                    )
                case .countdown(let plan, let route):
                    CountdownView(
                        viewModel: CountdownViewModel(
                            plan: plan,
                            route: route,
                            cuePlayer: dependencies.cuePlayer,
                            settings: dependencies.settingsStore.load(),
                            onFinished: { plan, route in coordinator.push(.execution(plan, route)) },
                            onCancel: { coordinator.pop() }
                        )
                    )
                case .execution(let plan, let route):
                    ExecutionView(
                        viewModel: ExecutionViewModel(
                            clock: dependencies.clock,
                            locationProvider: dependencies.locationProvider,
                            cuePlayer: dependencies.cuePlayer,
                            settings: dependencies.settingsStore.load(),
                            plan: plan,
                            route: route,
                            onNext: { metrics in coordinator.push(.results(metrics)) }
                        )
                    )
                case .results(let metrics):
                    ResultsView(
                        viewModel: ResultsViewModel(
                            metrics: metrics,
                            onDone: { coordinator.popToRoot() }
                        )
                    )
                }
            }
        }
        .environment(\.appDependencies, dependencies)
    }
}
