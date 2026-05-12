// Target: PikminMushroomAlarm (main app) + ShareExtension
// Shared via App Group so both targets read/write the same SwiftData store.

import Foundation
import SwiftData

@Model
final class Mushroom {
    @Attribute(.unique) var id: UUID
    var location: String
    var type: String
    var finishDate: Date
    var respawnDate: Date
    var createdAt: Date

    init(
        id: UUID = UUID(),
        location: String,
        type: String,
        finishDate: Date,
        respawnDate: Date,
        createdAt: Date = .now
    ) {
        self.id = id
        self.location = location
        self.type = type
        self.finishDate = finishDate
        self.respawnDate = respawnDate
        self.createdAt = createdAt
    }

    var remainingSeconds: Int {
        max(0, Int(finishDate.timeIntervalSinceNow))
    }

    var secondsUntilRespawn: Int {
        max(0, Int(respawnDate.timeIntervalSinceNow))
    }

    var hasRespawned: Bool {
        Date.now >= respawnDate
    }
}
