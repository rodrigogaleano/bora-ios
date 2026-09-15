import CoreLocation
import Foundation

struct PlannedRoute: Hashable {
    var start: RouteCoordinate
    var outboundPoints: [RouteCoordinate]
}

extension PlannedRoute {
    var outboundPath: [RouteCoordinate] {
        [start] + outboundPoints
    }

    var returnPath: [RouteCoordinate] {
        outboundPath.reversed()
    }

    var outboundDistanceMeters: Double {
        zip(outboundPath, outboundPath.dropFirst())
            .reduce(0) { total, pair in
                total + pair.0.clLocation.distance(from: pair.1.clLocation)
            }
    }

    var totalDistanceMeters: Double {
        outboundDistanceMeters * 2
    }

    var isValid: Bool {
        !outboundPoints.isEmpty
    }
}
