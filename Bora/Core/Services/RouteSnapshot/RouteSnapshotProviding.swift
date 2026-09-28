import UIKit

protocol RouteSnapshotProviding {
    func snapshot(route: [RouteCoordinate], size: CGSize) async throws -> UIImage
}
