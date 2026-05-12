// Target: PikminMushroomAlarm + ShareExtension
// Mirrors NOTIFY_STEPS in pikmin_alarm_mockup.jsx and proposal §4.2.

import Foundation

enum NotificationOffset: Int, CaseIterable, Identifiable {
    case finished = 0
    case twoMinutes = 180
    case oneMinute = 240
    case thirtySeconds = 270
    case tenSeconds = 290
    case respawn = 300

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .finished:      return "蘑菇結束"
        case .twoMinutes:    return "倒數 2 分鐘"
        case .oneMinute:     return "倒數 1 分鐘"
        case .thirtySeconds: return "倒數 30 秒"
        case .tenSeconds:    return "倒數 10 秒"
        case .respawn:       return "刷新時間"
        }
    }

    var tone: String {
        switch self {
        case .finished:      return "任務完成，準備刷新"
        case .twoMinutes:    return "新蘑菇快出現"
        case .oneMinute:     return "準備打開 Pikmin"
        case .thirtySeconds: return "提醒變頻繁"
        case .tenSeconds:    return "最後提醒"
        case .respawn:       return "新蘑菇可能出現了"
        }
    }

    var offsetLabel: String {
        let minutes = rawValue / 60
        let seconds = rawValue % 60
        return String(format: "T + %d:%02d", minutes, seconds)
    }

    func fireDate(after finishDate: Date) -> Date {
        finishDate.addingTimeInterval(TimeInterval(rawValue))
    }
}
