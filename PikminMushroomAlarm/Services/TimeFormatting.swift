// Target: PikminMushroomAlarm + ShareExtension
// Pure helpers — mirrors twoDigits/formatTime from pikmin_alarm_mockup.jsx.

import Foundation

enum TimeFormatting {
    /// "HH:MM:SS", clamping negatives to zero.
    static func hms(seconds: Int) -> String {
        let safe = max(0, seconds)
        let h = safe / 3600
        let m = (safe % 3600) / 60
        let s = safe % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    /// "HH:MM" of an absolute clock time, used for finish/respawn labels.
    static func clock(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
