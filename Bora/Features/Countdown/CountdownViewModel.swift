import Foundation

@Observable
final class CountdownViewModel {
    let plan: SessionPlan
    let route: PlannedRoute
    private let cuePlayer: RunCueProviding
    private let settings: RunSettings
    private let onFinished: (SessionPlan, PlannedRoute) -> Void
    private let onCancel: () -> Void

    private(set) var count: Int
    private var task: Task<Void, Never>?

    init(
        plan: SessionPlan,
        route: PlannedRoute,
        cuePlayer: RunCueProviding,
        settings: RunSettings,
        startingFrom: Int = 3,
        onFinished: @escaping (SessionPlan, PlannedRoute) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.plan = plan
        self.route = route
        self.cuePlayer = cuePlayer
        self.settings = settings
        self.count = startingFrom
        self.onFinished = onFinished
        self.onCancel = onCancel
    }

    func start() {
        guard task == nil else { return }
        cuePlayer.prepare(settings: settings)
        cuePlayer.play(.countdownTick(count))
        task = Task { [weak self] in
            while let self, self.count > 0, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                self.tick()
            }
        }
    }

    func tick() {
        guard count > 0 else { return }
        count -= 1
        if count == 0 {
            onFinished(plan, route)
            return
        }
        cuePlayer.play(.countdownTick(count))
    }

    func cancel() {
        task?.cancel()
        cuePlayer.teardown()
        onCancel()
    }
}
