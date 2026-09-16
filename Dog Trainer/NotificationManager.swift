import Foundation
import SwiftUI
import UserNotifications

// MARK: - Notification IDs

enum NotificationID {
    static let dailyReminder  = "DogAcademy.dailyReminder"
    static let streakAtRisk   = "DogAcademy.streakAtRisk"
}

// MARK: - Permission status

enum NotificationPermission: Equatable {
    case unknown
    case denied
    case authorized
    case provisional

    var isGranted: Bool {
        self == .authorized || self == .provisional
    }
}

// MARK: - NotificationManager

@MainActor
@Observable
final class NotificationManager {

    // MARK: Public state

    var permission: NotificationPermission = .unknown

    /// Година денного нагадування (за замовчанням 09:00)
    @ObservationIgnored
    @AppStorage("notif.dailyHour") var dailyReminderHour: Int = 9

    // MARK: - Public API

    /// Завантажує статус дозволу системно.
    func refreshPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized:    permission = .authorized
        case .provisional:   permission = .provisional
        case .denied:        permission = .denied
        case .notDetermined: permission = .unknown
        case .ephemeral:     permission = .authorized
        @unknown default:    permission = .unknown
        }
    }

    /// Запитати дозвіл у користувача.
    @discardableResult
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            await refreshPermission()
            return granted
        } catch {
            await refreshPermission()
            return false
        }
    }

    /// Перепланувати щоденне нагадування + нагадування про streak.
    /// Викликати після зміни налаштувань, збереження сесії, запуску app.
    func rescheduleAll(dog: Dog?) async {
        await refreshPermission()
        guard permission.isGranted else { return }

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [
            NotificationID.dailyReminder,
            NotificationID.streakAtRisk
        ])

        guard let dog else { return }

        scheduleDailyReminder(dogName: dog.name)
        if dog.currentStreak > 0 && !dog.trainedToday {
            scheduleStreakAtRisk(dogName: dog.name, streak: dog.currentStreak)
        }
    }

    /// Зняти всі нагадування (наприклад, при видаленні собаки).
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Private — daily reminder

    private func scheduleDailyReminder(dogName: String) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notif.daily.title")
        content.body  = String(localized: "notif.daily.body \(dogName)")
        content.sound = .default

        var components = DateComponents()
        components.hour   = dailyReminderHour
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationID.dailyReminder,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Private — streak at risk

    /// Якщо у собаки активний streak і вона ще не тренувалась сьогодні —
    /// нагадуємо ввечері (20:00), щоб не загубили streak.
    private func scheduleStreakAtRisk(dogName: String, streak: Int) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notif.streak.title")
        content.body  = String(localized: "notif.streak.body \(dogName) \(streak)")
        content.sound = .default

        var components = DateComponents()
        components.hour   = 20
        components.minute = 0

        // Тільки на сьогодні: одноразовий
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: NotificationID.streakAtRisk,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}
