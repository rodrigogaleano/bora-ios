import CoreLocation

/// A GPS fix as the run needs to judge it: where it says you are, and how far off it admits
/// it could be. `RouteCoordinate` stays accuracy-free because planned routes have none.
struct LocationSample: Hashable {
    /// Accuracy assumed when the caller doesn't say — good enough to pass every level.
    static let defaultHorizontalAccuracy: Double = 5

    var coordinate: RouteCoordinate
    /// Radius of uncertainty in meters. Negative means CoreLocation couldn't determine it.
    var horizontalAccuracy: Double

    init(coordinate: RouteCoordinate, horizontalAccuracy: Double = LocationSample.defaultHorizontalAccuracy) {
        self.coordinate = coordinate
        self.horizontalAccuracy = horizontalAccuracy
    }

    init(_ location: CLLocation) {
        self.init(
            coordinate: RouteCoordinate(location.coordinate),
            horizontalAccuracy: location.horizontalAccuracy
        )
    }
}
