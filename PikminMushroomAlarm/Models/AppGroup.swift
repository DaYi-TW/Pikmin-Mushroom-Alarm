// Target: PikminMushroomAlarm + ShareExtension
// Update `identifier` to match the App Group you create in Apple Developer
// (must also match both targets' .entitlements files).

import Foundation

enum AppGroup {
    static let identifier = "group.com.yourname.pikminmushroomalarm"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    static var storeURL: URL? {
        containerURL?.appendingPathComponent("PikminMushroomAlarm.sqlite")
    }
}
