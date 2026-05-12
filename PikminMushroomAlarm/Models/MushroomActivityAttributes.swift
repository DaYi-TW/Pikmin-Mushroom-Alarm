// Target: PikminMushroomAlarm + PikminWidgets
// ActivityAttributes describes the stable identity of one Live Activity instance,
// and ContentState carries the data that changes over time.
//
// We intentionally pass Dates (not remaining seconds) into ContentState so the
// widget can use SwiftUI's Text(timerInterval:) for free per-second updates —
// otherwise we'd have to push updates every second from the main app, which
// ActivityKit rate-limits aggressively.

import Foundation
import ActivityKit

struct MushroomActivityAttributes: ActivityAttributes {
    typealias ContentState = MushroomState

    struct MushroomState: Codable, Hashable {
        var finishDate: Date
        var respawnDate: Date
    }

    var mushroomID: UUID
    var location: String
    var type: String
}
