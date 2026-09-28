import CoreGraphics
import Foundation

enum RouteShape {
    static func normalized(_ coordinates: [RouteCoordinate]) -> [CGPoint] {
        guard coordinates.count > 1 else { return [] }
        let meanLatitude = coordinates.map(\.latitude).reduce(0, +) / Double(coordinates.count)
        let xScale = cos(meanLatitude * .pi / 180)
        let projected = coordinates.map { CGPoint(x: $0.longitude * xScale, y: -$0.latitude) }

        let longitudes = projected.map(\.x)
        let latitudes = projected.map(\.y)
        guard let minX = longitudes.min(), let maxX = longitudes.max(),
              let minY = latitudes.min(), let maxY = latitudes.max() else { return [] }
        let span = max(maxX - minX, maxY - minY)
        guard span > 0 else { return [] }
        let xOffset = (span - (maxX - minX)) / 2
        let yOffset = (span - (maxY - minY)) / 2
        return projected.map { point in
            CGPoint(x: (point.x - minX + xOffset) / span, y: (point.y - minY + yOffset) / span)
        }
    }
}
