import CoreLocation

/// Decides whether a GPS fix is trustworthy enough to count toward a run. Pure on purpose:
/// every number the runner sees (distance, pace, phase changes gated by distance) is built
/// from the fixes this lets through.
enum LocationQualityFilter {
    /// - Parameters:
    ///   - last: the last fix that was accepted, if any.
    ///   - elapsed: seconds since that fix. Non-positive means speed can't be judged.
    static func accepts(
        _ sample: LocationSample,
        after last: RouteCoordinate?,
        elapsed: TimeInterval,
        accuracy: GPSAccuracy
    ) -> Bool {
        guard sample.horizontalAccuracy >= 0,
              sample.horizontalAccuracy <= accuracy.maximumHorizontalAccuracy else {
            return false
        }
        guard let last, elapsed > 0 else { return true }
        let distance = last.clLocation.distance(from: sample.coordinate.clLocation)
        return distance / elapsed <= GPSAccuracy.maximumSpeedMetersPerSecond
    }
}
