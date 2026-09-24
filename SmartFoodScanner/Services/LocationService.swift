import CoreLocation
import Foundation

final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let notificationService: NotificationService
    private var arrivalTimes: [String: Date] = [:]

    init(notificationService: NotificationService) {
        self.notificationService = notificationService
        super.init()
        manager.delegate = self
    }

    func startShoppingAwareness() async {
        await notificationService.requestPermission()
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let key = gridKey(for: location)
        let firstSeen = arrivalTimes[key] ?? Date()
        arrivalTimes[key] = firstSeen

        guard Date().timeIntervalSince(firstSeen) >= 120 else { return }
        Task {
            await notificationService.sendShoppingTipIfAllowed(locationKey: key)
        }
    }

    private func gridKey(for location: CLLocation) -> String {
        let lat = (location.coordinate.latitude * 1000).rounded() / 1000
        let lon = (location.coordinate.longitude * 1000).rounded() / 1000
        return "\(lat),\(lon)"
    }
}
