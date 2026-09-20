import Foundation

protocol LocationProviding {
    func requestCurrentLocation() async throws -> RouteCoordinate
    /// Continuous location updates for an active run. The stream ends when
    /// `stopLocationUpdates()` is called.
    func startLocationUpdates(accuracy: GPSAccuracy) -> AsyncStream<LocationSample>
    func stopLocationUpdates()
}
