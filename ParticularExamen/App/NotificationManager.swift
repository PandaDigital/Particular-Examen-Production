import Foundation
import UserNotifications

enum NotificationManager {
    static func requestPermissionAndSchedule(_ schedule: NotificationSchedule) async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        guard granted else { throw NotificationError.permissionDenied }
        try await apply(schedule)
    }

    static func apply(_ schedule: NotificationSchedule) async throws {
        let center = UNUserNotificationCenter.current()
        let identifiers = ["examen.morning", "examen.midday", "examen.evening"]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)

        if schedule.morningEnabled {
            try await add(
                identifier: identifiers[0],
                title: "Name the fault",
                body: "Ask for grace and resolve to guard against your chosen vice today.",
                hour: schedule.morningHour,
                minute: schedule.morningMinute
            )
        }
        if schedule.middayEnabled {
            try await add(
                identifier: identifiers[1],
                title: "Make the first count",
                body: "Pause, remember each fall since morning, and renew your resolve.",
                hour: schedule.middayHour,
                minute: schedule.middayMinute
            )
        }
        if schedule.eveningEnabled {
            try await add(
                identifier: identifiers[2],
                title: "Complete the Examen",
                body: "Count the afternoon, compare the day, and entrust tomorrow to God.",
                hour: schedule.eveningHour,
                minute: schedule.eveningMinute
            )
        }
    }

    private static func add(
        identifier: String,
        title: String,
        body: String,
        hour: Int,
        minute: Int
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        try await UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        )
    }

    enum NotificationError: LocalizedError {
        case permissionDenied

        var errorDescription: String? {
            "Notifications are disabled. Enable them for Particular Examen in iOS Settings."
        }
    }
}
