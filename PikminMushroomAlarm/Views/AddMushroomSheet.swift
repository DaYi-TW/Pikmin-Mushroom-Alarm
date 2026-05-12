// Target: PikminMushroomAlarm
// Mirrors AddMushroomSheet in pikmin_alarm_mockup.jsx, but actually runs OCR.

import SwiftUI
import PhotosUI

struct AddMushroomSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onParsed: (OCRResult) -> Void

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var results: [OCRResult] = []
    @State private var isProcessing = false
    @State private var errorMessage: String?

    private let ocr = OCRService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    PhotosPicker(
                        selection: $pickerItems,
                        maxSelectionCount: 10,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        VStack(spacing: 10) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 36))
                            Text("選擇 Pikmin 截圖")
                                .font(.headline)
                            Text("可一次選多張，自動建立蘑菇鬧鐘")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                                .foregroundStyle(.green)
                                .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
                        )
                    }

                    if isProcessing {
                        ProgressView("辨識中…")
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    ForEach(Array(results.enumerated()), id: \.offset) { _, result in
                        previewRow(result)
                    }
                }
                .padding(20)
            }
            .navigationTitle("新增蘑菇")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        for result in results { onParsed(result) }
                        dismiss()
                    }
                    .disabled(results.isEmpty)
                }
            }
            .onChange(of: pickerItems) { _, items in
                Task { await process(items: items) }
            }
        }
    }

    private func previewRow(_ result: OCRResult) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.location.isEmpty ? "未知地點" : result.location)
                    .font(.headline)
                Text(result.type.isEmpty ? "未知類型" : result.type)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(TimeFormatting.hms(seconds: result.remainingSeconds))
                .font(.title3.weight(.black))
                .monospacedDigit()
        }
        .padding(16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18))
    }

    private func process(items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        isProcessing = true
        errorMessage = nil
        var parsed: [OCRResult] = []
        for item in items {
            guard
                let data = try? await item.loadTransferable(type: Data.self),
                let image = UIImage(data: data)
            else { continue }
            do {
                let result = try await ocr.recognize(image: image)
                parsed.append(result)
            } catch {
                errorMessage = "有一張圖片辨識失敗：\(error)"
            }
        }
        results = parsed
        isProcessing = false
    }
}
