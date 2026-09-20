import Foundation

struct PreviewLocationProvider: LocationProviding {
    var coordinate = RouteCoordinate(latitude: -23.5614, longitude: -46.6560)
    var delay: Duration = .milliseconds(300)
    var error: Error?
    var updates: [LocationSample] = []
    var updateInterval: Duration = .milliseconds(300)

    func requestCurrentLocation() async throws -> RouteCoordinate {
        try await Task.sleep(for: delay)
        if let error {
            throw error
        }
        return coordinate
    }

    func startLocationUpdates(accuracy: GPSAccuracy) -> AsyncStream<LocationSample> {
        AsyncStream { continuation in
            let task = Task {
                for point in updates {
                    try? await Task.sleep(for: updateInterval)
                    if Task.isCancelled { break }
                    continuation.yield(point)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func stopLocationUpdates() {}
}
