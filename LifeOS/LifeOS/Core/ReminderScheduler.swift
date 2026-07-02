import Foundation
import UserNotifications

protocol ReminderScheduling {
    func requestAuthorization() async -> Bool
    func schedule(_ reminder: Reminder)
    func cancel(reminderID: UUID)
}

final class LocalReminderScheduler: ReminderScheduling {
    static let shared = LocalReminderScheduler()

    private init() {}

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func schedule(_ reminder: Reminder) {
        guard reminder.enabled, reminder.scheduledAt > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.message.isEmpty ? "LifeOS reminder" : reminder.message
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.scheduledAt)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancel(reminderID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderID.uuidString])
    }
}
