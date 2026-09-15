import Foundation

protocol LocationProviding {
    func requestCurrentLocation() async throws -> RouteCoordinate
}
