import Foundation

struct PreviewLocationProvider: LocationProviding {
    var coordinate = RouteCoordinate(latitude: -23.5614, longitude: -46.6560)
    var delay: Duration = .milliseconds(300)
    var error: Error?

    func requestCurrentLocation() async throws -> RouteCoordinate {
        try await Task.sleep(for: delay)
        if let error {
            throw error
        }
        return coordinate
    }
}
