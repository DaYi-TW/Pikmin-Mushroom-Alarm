// Target: ShareExtension
// Embedded extension. Receives a screenshot share, runs Vision OCR, writes
// a Mushroom into the shared SwiftData store, schedules notifications, and
// closes itself. The main app sees the new mushroom on next launch.
//
// In Xcode: File → New → Target → Share Extension. Replace the generated
// ShareViewController.swift with this file. Add the same App Group to this
// target's .entitlements. Add Mushroom.swift, NotificationOffset.swift,
// AppGroup.swift, OCRService.swift, NotificationScheduler.swift, MushroomStore.swift
// to this target's membership.

import UIKit
import SwiftData
import UniformTypeIdentifiers
import WidgetKit

class ShareViewController: UIViewController {
    private let ocr = OCRService()
    private let scheduler = NotificationScheduler()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        Task { await handleSharedItems() }
    }

    private func handleSharedItems() async {
        let inputItems = (extensionContext?.inputItems as? [NSExtensionItem]) ?? []
        let attachments = inputItems.flatMap { $0.attachments ?? [] }

        var savedCount = 0

        for provider in attachments where provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            guard let image = await loadImage(from: provider) else { continue }
            guard let result = try? await ocr.recognize(image: image) else { continue }
            if await saveAndSchedule(result: result) {
                savedCount += 1
            }
        }

        if savedCount > 0 {
            WidgetCenter.shared.reloadAllTimelines()
        }
        await MainActor.run { finish(savedCount: savedCount) }
    }

    private func loadImage(from provider: NSItemProvider) async -> UIImage? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, _ in
                if let image = item as? UIImage {
                    continuation.resume(returning: image)
                } else if let url = item as? URL, let data = try? Data(contentsOf: url) {
                    continuation.resume(returning: UIImage(data: data))
                } else if let data = item as? Data {
                    continuation.resume(returning: UIImage(data: data))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    @MainActor
    private func saveAndSchedule(result: OCRResult) async -> Bool {
        let container = MushroomStore.shared
        let context = container.mainContext
        let mushroom = MushroomStore.insert(result, into: context)
        await scheduler.schedule(for: mushroom)
        return true
    }

    private func finish(savedCount: Int) {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
