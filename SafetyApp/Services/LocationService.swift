import CoreLocation

@MainActor
final class LocationService: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentCoordinate: CLLocationCoordinate2D?
    @Published var isTracking = false

    private var locationHistory: [(coordinate: CLLocationCoordinate2D, timestamp: Date)] = []

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.allowsBackgroundLocationUpdates = false
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func getCurrentLocation() async throws -> CLLocationCoordinate2D {
        let status = manager.authorizationStatus
        if status == .notDetermined {
            requestPermission()
            try await Task.sleep(for: .seconds(1))
        }

        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            throw LocationError.permissionDenied
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
        }
    }

    func startContinuousTracking() {
        let status = manager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            requestPermission()
            return
        }

        isTracking = true
        locationHistory.removeAll()
        manager.distanceFilter = 5
        manager.startUpdatingLocation()
    }

    func stopContinuousTracking() {
        isTracking = false
        manager.stopUpdatingLocation()
    }

    func getLocationHistory() -> [(coordinate: CLLocationCoordinate2D, timestamp: Date)] {
        return locationHistory
    }

    func getLatestCoordinate() -> CLLocationCoordinate2D? {
        return currentCoordinate
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            currentCoordinate = location.coordinate
            locationHistory.append((coordinate: location.coordinate, timestamp: Date()))

            if let cont = continuation {
                cont.resume(returning: location.coordinate)
                continuation = nil
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            if let cont = continuation {
                cont.resume(throwing: error)
                continuation = nil
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            if isTracking && (manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways) {
                manager.startUpdatingLocation()
            }
        }
    }
}

enum LocationError: LocalizedError {
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission is required to send your location in an emergency alert. Please enable it in Settings."
        }
    }
}
