import CoreLocation
import Testing
@testable import Bora

struct PlannedRouteTests {
    @Test func outboundDistanceIsSumOfSegments() {
        let route = PlannedRoute(
            start: RouteCoordinate(latitude: 0, longitude: 0),
            outboundPoints: [
                RouteCoordinate(latitude: 0, longitude: 0.001),
                RouteCoordinate(latitude: 0, longitude: 0.002)
            ]
        )
        let segment1 = route.start.clLocation.distance(from: route.outboundPoints[0].clLocation)
        let segment2 = route.outboundPoints[0].clLocation.distance(from: route.outboundPoints[1].clLocation)
        #expect(abs(route.outboundDistanceMeters - (segment1 + segment2)) < 0.001)
    }

    @Test func totalDistanceIsDoubleOutbound() {
        let route = PlannedRoute(
            start: RouteCoordinate(latitude: 0, longitude: 0),
            outboundPoints: [RouteCoordinate(latitude: 0, longitude: 0.001)]
        )
        #expect(route.totalDistanceMeters == route.outboundDistanceMeters * 2)
    }

    @Test func returnPathIsReversedOutboundPath() {
        let route = PlannedRoute(
            start: RouteCoordinate(latitude: 0, longitude: 0),
            outboundPoints: [
                RouteCoordinate(latitude: 0, longitude: 0.001),
                RouteCoordinate(latitude: 0, longitude: 0.002)
            ]
        )
        #expect(route.returnPath == route.outboundPath.reversed())
    }

    @Test func isValidRequiresAtLeastOneOutboundPoint() {
        let empty = PlannedRoute(start: RouteCoordinate(latitude: 0, longitude: 0), outboundPoints: [])
        #expect(!empty.isValid)

        let withPoint = PlannedRoute(
            start: RouteCoordinate(latitude: 0, longitude: 0),
            outboundPoints: [RouteCoordinate(latitude: 0, longitude: 0.001)]
        )
        #expect(withPoint.isValid)
    }

    @Test func emptyOutboundPointsProducesZeroDistance() {
        let route = PlannedRoute(start: RouteCoordinate(latitude: 0, longitude: 0), outboundPoints: [])
        #expect(route.outboundDistanceMeters == 0)
        #expect(route.totalDistanceMeters == 0)
    }
}
