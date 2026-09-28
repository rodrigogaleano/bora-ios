import CoreGraphics
import Testing
@testable import Bora

struct RouteShapeTests {
    @Test func pointsFitTheUnitSquare() {
        let points = RouteShape.normalized([
            RouteCoordinate(latitude: -23.55, longitude: -46.63),
            RouteCoordinate(latitude: -23.56, longitude: -46.62),
            RouteCoordinate(latitude: -23.54, longitude: -46.64)
        ])

        #expect(points.count == 3)
        #expect(points.allSatisfy { (0...1).contains($0.x) && (0...1).contains($0.y) })
    }

    @Test func northIsUp() {
        let points = RouteShape.normalized([
            RouteCoordinate(latitude: 0, longitude: 0),
            RouteCoordinate(latitude: 0.01, longitude: 0)
        ])

        #expect(points[1].y < points[0].y)
    }

    @Test func wideRouteKeepsItsProportionCentered() {
        let points = RouteShape.normalized([
            RouteCoordinate(latitude: 0, longitude: 0),
            RouteCoordinate(latitude: 0, longitude: 0.02),
            RouteCoordinate(latitude: 0.01, longitude: 0.02)
        ])

        #expect(points[0].x == 0)
        #expect(points[1].x == 1)
        #expect(abs((points[1].y - points[2].y) - 0.5) < 0.001)
        #expect(abs(points[0].y - 0.75) < 0.001)
    }

    @Test func singlePointHasNoShape() {
        #expect(RouteShape.normalized([RouteCoordinate(latitude: 1, longitude: 1)]).isEmpty)
        #expect(RouteShape.normalized([]).isEmpty)
    }
}
