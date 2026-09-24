import Foundation
import UserNotifications

final class NotificationService {
    func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    func sendShoppingTipIfAllowed(locationKey: String) async {
        let todayKey = "shopping-tip-\(locationKey)-\(Self.dayStamp)"
        guard UserDefaults.standard.bool(forKey: todayKey) == false else { return }

        let content = UNMutableNotificationContent()
        content.title = "Quick tip"
        content.body = "Scan before you buy to understand what is inside."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: todayKey,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )

        try? await UNUserNotificationCenter.current().add(request)
        UserDefaults.standard.set(true, forKey: todayKey)
    }

    private static var dayStamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
