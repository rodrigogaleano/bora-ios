import Foundation

@Observable
final class RouteViewModel {
    enum LoadingState: Equatable {
        case loadingInitialFix
        case ready
        case failed
    }

    private let clock: ClockProviding
    private let locationProvider: LocationProviding
    let plan: SessionPlan
    private let onNext: (SessionPlan, PlannedRoute) -> Void

    var loadingState: LoadingState = .loadingInitialFix
    var start: RouteCoordinate?
    var outboundPoints: [RouteCoordinate] = []

    init(
        clock: ClockProviding,
        locationProvider: LocationProviding,
        plan: SessionPlan,
        onNext: @escaping (SessionPlan, PlannedRoute) -> Void
    ) {
        self.clock = clock
        self.locationProvider = locationProvider
        self.plan = plan
        self.onNext = onNext
    }

    var route: PlannedRoute? {
        start.map { PlannedRoute(start: $0, outboundPoints: outboundPoints) }
    }

    var totalDistanceMeters: Double {
        route?.totalDistanceMeters ?? 0
    }

    var isValid: Bool {
        route?.isValid ?? false
    }

    func requestInitialLocation() async {
        loadingState = .loadingInitialFix
        do {
            start = try await locationProvider.requestCurrentLocation()
            loadingState = .ready
        } catch {
            loadingState = .failed
        }
    }

    func addPoint(_ coordinate: RouteCoordinate) {
        guard loadingState == .ready else { return }
        outboundPoints.append(coordinate)
    }

    func moveStartPoint(to coordinate: RouteCoordinate) {
        start = coordinate
    }

    func redo() {
        outboundPoints.removeAll()
    }

    func next() {
        guard let route, isValid else { return }
        onNext(plan, route)
    }
}
