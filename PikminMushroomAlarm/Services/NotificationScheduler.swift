// Target: PikminMushroomAlarm + ShareExtension
// Schedules the escalating reminder sequence from proposal §4.2.

import Foundation
import UserNotifications

struct NotificationScheduler {
    let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge, .timeSensitive])
    }

    func schedule(for mushroom: Mushroom) async {
        await cancel(for: mushroom)

        for offset in NotificationOffset.allCases {
            let fireDate = offset.fireDate(after: mushroom.finishDate)
            // Skip offsets already in the past — UNNotification won't fire them anyway.
            guard fireDate > Date.now else { continue }

            let content = UNMutableNotificationContent()
            content.title = "\(mushroom.location) · \(offset.label)"
            content.body = "\(mushroom.type) — \(offset.tone)"
            content.sound = .default
            content.interruptionLevel = (offset == .respawn || offset == .tenSeconds) ? .timeSensitive : .active
            content.userInfo = [
                "mushroomID": mushroom.id.uuidString,
                "offset": offset.rawValue
            ]

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: identifier(for: mushroom, offset: offset),
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    func cancel(for mushroom: Mushroom) async {
        let ids = NotificationOffset.allCases.map { identifier(for: mushroom, offset: $0) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    private func identifier(for mushroom: Mushroom, offset: NotificationOffset) -> String {
        "mushroom.\(mushroom.id.uuidString).\(offset.rawValue)"
    }
}
