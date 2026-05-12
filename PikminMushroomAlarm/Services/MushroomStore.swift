// Target: PikminMushroomAlarm + ShareExtension
// SwiftData container backed by the App Group, so the Share Extension
// and the main app see the same mushrooms.

import Foundation
import SwiftData

@MainActor
enum MushroomStore {
    static let shared: ModelContainer = {
        let schema = Schema([Mushroom.self])
        let config: ModelConfiguration
        if let url = AppGroup.storeURL {
            config = ModelConfiguration(schema: schema, url: url)
        } else {
            // Fallback for previews / unit tests without the App Group entitlement.
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to build ModelContainer: \(error)")
        }
    }()

    static func insert(_ result: OCRResult, into context: ModelContext) -> Mushroom {
        let mushroom = Mushroom(
            location: result.location,
            type: result.type,
            finishDate: result.finishDate,
            respawnDate: result.respawnDate
        )
        context.insert(mushroom)
        try? context.save()
        return mushroom
    }
}
