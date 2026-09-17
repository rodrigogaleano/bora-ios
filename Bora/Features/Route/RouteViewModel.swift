import Foundation

@Observable
final class RouteViewModel {
    enum LoadingState: Equatable {
        case loadingInitialFix
        case ready
        case failed
    }

    private let locationProvider: LocationProviding
    private let onDone: (PlannedRoute) -> Void

    var loadingState: LoadingState = .loadingInitialFix
    var start: RouteCoordinate?
    var outboundPoints: [RouteCoordinate] = []

    /// `existingRoute` reopens the screen on a route already drawn — editing it must not
    /// start from a blank map.
    init(
        locationProvider: LocationProviding,
        existingRoute: PlannedRoute? = nil,
        onDone: @escaping (PlannedRoute) -> Void
    ) {
        self.locationProvider = locationProvider
        self.onDone = onDone
        if let existingRoute {
            start = existingRoute.start
            outboundPoints = existingRoute.outboundPoints
            loadingState = .ready
        }
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
        guard loadingState != .ready else { return }
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
        onDone(route)
    }
}
