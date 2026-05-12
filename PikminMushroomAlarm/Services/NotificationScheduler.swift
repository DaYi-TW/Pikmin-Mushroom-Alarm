// Target: PikminMushroomAlarm + ShareExtension
// Schedules the escalating reminder sequence from proposal §4.2.
//
// Apple Watch behavior (Phase A, no watchOS app):
//   When the iPhone is locked / screen off and a paired Watch is on-wrist, iOS
//   forwards these notifications to the Watch automatically. The category +
//   actions below are surfaced as buttons on the Watch banner. `.timeSensitive`
//   + a high `relevanceScore` makes near-respawn alerts cut through Focus modes.

import Foundation
import UserNotifications

enum MushroomNotification {
    static let categoryID = "MUSHROOM_REMINDER"
    static let openGameActionID = "OPEN_GAME"
    static let snoozeActionID = "SNOOZE_1_MIN"

    static var category: UNNotificationCategory {
        let openGame = UNNotificationAction(
            identifier: openGameActionID,
            title: "打開 Pikmin Bloom",
            options: [.foreground]
        )
        let snooze = UNNotificationAction(
            identifier: snoozeActionID,
            title: "再提醒 1 分鐘",
            options: []
        )
        return UNNotificationCategory(
            identifier: categoryID,
            actions: [openGame, snooze],
            intentIdentifiers: [],
            options: [.hiddenPreviewsShowTitle]
        )
    }
}

struct NotificationScheduler {
    let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge, .timeSensitive])
    }

    /// Reads the current authorization status without prompting. UI uses this
    /// after `requestAuthorization` to decide whether to show a "permission
    /// denied" banner with a Settings deep link.
    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func registerCategories() {
        center.setNotificationCategories([MushroomNotification.category])
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
            content.categoryIdentifier = MushroomNotification.categoryID
            content.interruptionLevel = Self.interruptionLevel(for: offset)
            content.relevanceScore = Self.relevanceScore(for: offset)
            content.userInfo = [
                "mushroomID": mushroom.id.uuidString,
                "offset": offset.rawValue,
                "location": mushroom.location,
                "type": mushroom.type,
                "finishDate": mushroom.finishDate.timeIntervalSince1970,
                "respawnDate": mushroom.respawnDate.timeIntervalSince1970
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

    func scheduleSnooze(mushroomID: UUID, location: String, type: String, after seconds: TimeInterval = 60) async {
        let content = UNMutableNotificationContent()
        content.title = "\(location) · 延後提醒"
        content.body = "\(type) — 再次提醒你刷新時間"
        content.sound = .default
        content.categoryIdentifier = MushroomNotification.categoryID
        content.interruptionLevel = .timeSensitive
        content.relevanceScore = 1.0
        content.userInfo = ["mushroomID": mushroomID.uuidString, "snoozed": true]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(
            identifier: "mushroom.\(mushroomID.uuidString).snooze.\(Date.now.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    func cancel(for mushroom: Mushroom) async {
        let ids = NotificationOffset.allCases.map { identifier(for: mushroom, offset: $0) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    private func identifier(for mushroom: Mushroom, offset: NotificationOffset) -> String {
        "mushroom.\(mushroom.id.uuidString).\(offset.rawValue)"
    }

    // The closer to respawn, the higher the urgency. Apple Watch uses
    // interruptionLevel + relevanceScore to decide whether to wake the screen
    // and where to rank the notification in the stack.
    private static func interruptionLevel(for offset: NotificationOffset) -> UNNotificationInterruptionLevel {
        switch offset {
        case .tenSeconds, .respawn:   return .timeSensitive
        case .thirtySeconds:          return .timeSensitive
        default:                      return .active
        }
    }

    // 0.0 ... 1.0 — Watch + Notification Summary use this to prioritize.
    private static func relevanceScore(for offset: NotificationOffset) -> Double {
        switch offset {
        case .respawn:        return 1.0
        case .tenSeconds:     return 0.9
        case .thirtySeconds:  return 0.7
        case .oneMinute:      return 0.5
        case .twoMinutes:     return 0.3
        case .finished:       return 0.1
        }
    }
}
