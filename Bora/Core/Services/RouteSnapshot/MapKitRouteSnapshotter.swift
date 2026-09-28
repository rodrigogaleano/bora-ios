import MapKit
import UIKit

struct MapKitRouteSnapshotter: RouteSnapshotProviding {
    private static let edgePadding: CGFloat = 0.15
    private static let lineWidth: CGFloat = 5

    func snapshot(route: [RouteCoordinate], size: CGSize) async throws -> UIImage {
        let coordinates = route.map(\.clLocationCoordinate)
        let options = MKMapSnapshotter.Options()
        options.mapRect = Self.mapRect(fitting: coordinates, size: size)
        options.size = size
        options.traitCollection = UITraitCollection(userInterfaceStyle: .light)
        options.pointOfInterestFilter = .excludingAll

        let snapshot = try await MKMapSnapshotter(options: options).start()
        return UIGraphicsImageRenderer(size: size, format: snapshot.image.imageRendererFormat).image { _ in
            snapshot.image.draw(at: .zero)
            let path = UIBezierPath()
            for (index, coordinate) in coordinates.enumerated() {
                let point = snapshot.point(for: coordinate)
                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.lineWidth = Self.lineWidth
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            UIColor.systemBlue.setStroke()
            path.stroke()
        }
    }

    private static func mapRect(fitting coordinates: [CLLocationCoordinate2D], size: CGSize) -> MKMapRect {
        let bounds = MKPolyline(coordinates: coordinates, count: coordinates.count).boundingMapRect
        let aspect = size.width / max(size.height, 1)
        var width = bounds.width
        var height = bounds.height
        if width / max(height, 1) > aspect {
            height = width / aspect
        } else {
            width = height * aspect
        }
        width = max(width * (1 + edgePadding * 2), 1_000)
        height = max(height * (1 + edgePadding * 2), 1_000 / aspect)
        return MKMapRect(
            x: bounds.midX - width / 2,
            y: bounds.midY - height / 2,
            width: width,
            height: height
        )
    }
}
