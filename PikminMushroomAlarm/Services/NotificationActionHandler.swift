// Target: PikminMushroomAlarm
// UNUserNotificationCenterDelegate that:
//   1. Shows banners when the app is foregrounded (so testing isn't confusing).
//   2. Handles taps on the "再提醒 1 分鐘" / "打開 Pikmin Bloom" actions —
//      these buttons appear both on iPhone banners AND on the paired Apple
//      Watch's forwarded notification.
//
// "Open Pikmin Bloom" works via URL scheme. Pikmin Bloom's published scheme is
// `pikminbloom://`. If it ever changes, update `pikminBloomURL`.

import Foundation
import UserNotifications
import UIKit

final class NotificationActionHandler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationActionHandler()
    private let scheduler = NotificationScheduler()

    private let pikminBloomURL = URL(string: "pikminbloom://")!

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show the alert even when the app is in the foreground so the user
        // sees the same UX they'd get on Watch / lock screen.
        [.banner, .sound, .list]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard
            let mushroomIDString = userInfo["mushroomID"] as? String,
            let mushroomID = UUID(uuidString: mushroomIDString)
        else { return }

        switch response.actionIdentifier {
        case MushroomNotification.openGameActionID:
            await openPikminBloom()

        case MushroomNotification.snoozeActionID:
            let location = userInfo["location"] as? String ?? ""
            let type = userInfo["type"] as? String ?? ""
            await scheduler.scheduleSnooze(mushroomID: mushroomID, location: location, type: type)

        default:
            // Default tap: do nothing; the app will foreground naturally.
            break
        }
    }

    @MainActor
    private func openPikminBloom() async {
        guard await UIApplication.shared.canOpenURL(pikminBloomURL) else { return }
        await UIApplication.shared.open(pikminBloomURL)
    }
}
