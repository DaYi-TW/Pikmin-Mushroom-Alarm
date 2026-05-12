// Target: PikminMushroomAlarm
// Manual correction sheet for when OCR misreads a location, type, or remaining
// time. Editing the remaining time rebuilds finishDate / respawnDate from
// "now + new remaining" so notifications and Live Activities stay in sync.

import SwiftUI
import SwiftData
import WidgetKit

struct EditMushroomSheet: View {
    @Environment(\.dismiss) private var dismiss

    let mushroom: Mushroom
    let onSave: () -> Void

    @State private var location: String = ""
    @State private var type: String = ""
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0

    private let scheduler = NotificationScheduler()

    var body: some View {
        NavigationStack {
            Form {
                Section("地點 / 類型") {
                    TextField("地點", text: $location)
                    TextField("類型", text: $type)
                }

                Section("剩下時間") {
                    HStack {
                        timeField("小時", value: $hours, range: 0...23)
                        timeField("分", value: $minutes, range: 0...59)
                        timeField("秒", value: $seconds, range: 0...59)
                    }
                    Text("儲存後會以「現在 + 剩下時間」重新計算刷新時間。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("編輯蘑菇")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("儲存") {
                        Task { await save() }
                    }
                    .font(.subheadline.weight(.bold))
                    .disabled(location.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { populate() }
        }
    }

    private func timeField(_ label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            Picker(label, selection: value) {
                ForEach(range, id: \.self) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .clipped()
        }
    }

    private func populate() {
        location = mushroom.location
        type = mushroom.type
        let remaining = max(0, mushroom.remainingSeconds)
        hours = remaining / 3600
        minutes = (remaining % 3600) / 60
        seconds = remaining % 60
    }

    private func save() async {
        let totalSeconds = hours * 3600 + minutes * 60 + seconds
        let newFinish = Date.now.addingTimeInterval(TimeInterval(totalSeconds))
        let newRespawn = newFinish.addingTimeInterval(TimeInterval(NotificationOffset.respawn.rawValue))

        mushroom.location = location.trimmingCharacters(in: .whitespaces)
        mushroom.type = type.trimmingCharacters(in: .whitespaces)
        mushroom.finishDate = newFinish
        mushroom.respawnDate = newRespawn

        // Re-schedule notifications and refresh the Live Activity to match.
        await scheduler.schedule(for: mushroom)
        await LiveActivityManager.shared.update(for: mushroom)
        WidgetCenter.shared.reloadAllTimelines()
        onSave()
        dismiss()
    }
}
