import CoreLocation

final class SystemLocationProvider: NSObject, LocationProviding {
    enum LocationError: Error {
        case authorizationDenied
        case noLocationReturned
        case failed(Error)
    }

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<RouteCoordinate, Error>?
    private var isAwaitingAuthorization = false
    private var updatesContinuation: AsyncStream<LocationSample>.Continuation?

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestCurrentLocation() async throws -> RouteCoordinate {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            switch manager.authorizationStatus {
            case .notDetermined:
                isAwaitingAuthorization = true
                manager.requestWhenInUseAuthorization()
            case .denied, .restricted:
                resume(throwing: LocationError.authorizationDenied)
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            @unknown default:
                resume(throwing: LocationError.authorizationDenied)
            }
        }
    }

    func startLocationUpdates(accuracy: GPSAccuracy) -> AsyncStream<LocationSample> {
        manager.desiredAccuracy = accuracy.desiredAccuracy
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        manager.activityType = .fitness
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }
        manager.startUpdatingLocation()
        return AsyncStream { continuation in
            self.updatesContinuation = continuation
            continuation.onTermination = { [weak self] _ in
                self?.manager.stopUpdatingLocation()
            }
        }
    }

    func stopLocationUpdates() {
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
        updatesContinuation?.finish()
        updatesContinuation = nil
    }

    private func resume(returning coordinate: RouteCoordinate) {
        continuation?.resume(returning: coordinate)
        continuation = nil
    }

    private func resume(throwing error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

extension SystemLocationProvider: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard isAwaitingAuthorization else { return }
        isAwaitingAuthorization = false
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            resume(throwing: LocationError.authorizationDenied)
        case .notDetermined:
            break
        @unknown default:
            resume(throwing: LocationError.authorizationDenied)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            resume(throwing: LocationError.noLocationReturned)
            return
        }
        if continuation != nil {
            resume(returning: RouteCoordinate(location.coordinate))
        }
        // CoreLocation batches fixes when the app was suspended; every one counts toward
        // the run, not just the latest.
        for fix in locations {
            updatesContinuation?.yield(LocationSample(fix))
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        resume(throwing: LocationError.failed(error))
    }
}
