// Target: PikminMushroomAlarm
// Mirrors AddMushroomSheet in pikmin_alarm_mockup.jsx, but actually runs OCR.

import SwiftUI
import PhotosUI

private struct ParsedScreenshot: Identifiable {
    let id = UUID()
    var result: OCRResult
    var thumbnail: UIImage
}

struct AddMushroomSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onParsed: (OCRResult) -> Void

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var parsed: [ParsedScreenshot] = []
    @State private var isProcessing = false
    @State private var errorMessage: String?

    private let ocr = OCRService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    picker

                    if isProcessing {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("辨識中…").font(.footnote).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if !parsed.isEmpty {
                        sectionHeader
                        ForEach(parsed) { item in
                            previewCard(for: item)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("新增蘑菇")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        for item in parsed { onParsed(item.result) }
                        dismiss()
                    }
                    .disabled(parsed.isEmpty)
                    .fontWeight(.bold)
                }
            }
            .onChange(of: pickerItems) { _, items in
                Task { await process(items: items) }
            }
        }
    }

    private var picker: some View {
        PhotosPicker(
            selection: $pickerItems,
            maxSelectionCount: 10,
            matching: .images,
            photoLibrary: .shared()
        ) {
            VStack(spacing: 10) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 36))
                    .foregroundStyle(.green)
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
    }

    private var sectionHeader: some View {
        HStack {
            Text("辨識結果")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(parsed.count) 朵蘑菇")
                .font(.caption.weight(.bold))
                .foregroundStyle(.green)
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }

    private func previewCard(for item: ParsedScreenshot) -> some View {
        let result = item.result
        let hasLocation = !result.location.isEmpty
        let hasType = !result.type.isEmpty

        return HStack(alignment: .top, spacing: 14) {
            Image(uiImage: item.thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("🍄").font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(hasLocation ? result.location : "未知地點")
                            .font(.headline)
                            .foregroundStyle(hasLocation ? .primary : .secondary)
                            .lineLimit(1)
                        Text(hasType ? result.type : "未知類型")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 12) {
                    timeChip(label: "剩下", value: TimeFormatting.hms(seconds: result.remainingSeconds), tint: .primary)
                    timeChip(label: "刷新", value: TimeFormatting.clock(result.respawnDate), tint: .green)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func timeChip(label: String, value: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.black))
                .monospacedDigit()
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemGray6), in: Capsule())
    }

    private func process(items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        isProcessing = true
        errorMessage = nil
        var collected: [ParsedScreenshot] = []
        for item in items {
            guard
                let data = try? await item.loadTransferable(type: Data.self),
                let image = UIImage(data: data)
            else { continue }
            do {
                let result = try await ocr.recognize(image: image)
                collected.append(ParsedScreenshot(result: result, thumbnail: image))
            } catch {
                errorMessage = "有一張圖片辨識失敗：\(error.localizedDescription)"
            }
        }
        parsed = collected
        isProcessing = false
    }
}
