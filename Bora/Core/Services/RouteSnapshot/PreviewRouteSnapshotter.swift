import UIKit

struct PreviewRouteSnapshotter: RouteSnapshotProviding {
    func snapshot(route: [RouteCoordinate], size: CGSize) async throws -> UIImage {
        UIGraphicsImageRenderer(size: size).image { context in
            UIColor.systemGray5.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
