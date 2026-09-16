import Foundation

protocol LocationProviding {
    func requestCurrentLocation() async throws -> RouteCoordinate
    /// Continuous location updates for an active run. The stream ends when
    /// `stopLocationUpdates()` is called.
    func startLocationUpdates() -> AsyncStream<RouteCoordinate>
    func stopLocationUpdates()
}
