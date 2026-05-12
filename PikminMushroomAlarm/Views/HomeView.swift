// Target: PikminMushroomAlarm
// Mirrors HomeScreen + the host frame in pikmin_alarm_mockup.jsx.

import SwiftUI
import SwiftData
import WidgetKit

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Mushroom.createdAt, order: .reverse) private var mushrooms: [Mushroom]

    @State private var activeID: UUID?
    @State private var isAdding = false
    @State private var deleteTarget: Mushroom?

    private let scheduler = NotificationScheduler()

    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if mushrooms.isEmpty {
                        EmptyStateView { isAdding = true }
                    } else {
                        let selected = selectedMushroom ?? mushrooms[0]
                        HeroCardView(mushroom: selected)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(mushrooms) { mushroom in
                                    MushroomCardView(
                                        mushroom: mushroom,
                                        isActive: mushroom.id == selected.id,
                                        onSelect: { activeID = mushroom.id },
                                        onRequestDelete: { deleteTarget = mushroom }
                                    )
                                }
                            }
                            .padding(.horizontal, 4)
                        }

                        carouselDots(selectedID: selected.id)

                        Button { isAdding = true } label: {
                            Label("新增蘑菇鬧鐘", systemImage: "plus")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 56)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .controlSize(.large)

                        reminderRows
                    }
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $isAdding) {
            AddMushroomSheet { result in
                let mushroom = MushroomStore.insert(result, into: context)
                Task { await scheduler.schedule(for: mushroom) }
                LiveActivityManager.shared.start(for: mushroom)
                WidgetCenter.shared.reloadAllTimelines()
                activeID = mushroom.id
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $deleteTarget) { mushroom in
            DeleteConfirmSheet(mushroom: mushroom) {
                let mushroomID = mushroom.id
                Task {
                    await scheduler.cancel(for: mushroom)
                    await LiveActivityManager.shared.end(for: mushroomID)
                }
                context.delete(mushroom)
                try? context.save()
                WidgetCenter.shared.reloadAllTimelines()
                if activeID == mushroomID { activeID = nil }
            }
            .presentationDetents([.height(360)])
            .presentationDragIndicator(.visible)
        }
        .task {
            _ = try? await scheduler.requestAuthorization()
        }
    }

    private var selectedMushroom: Mushroom? {
        mushrooms.first { $0.id == activeID }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Pikmin Mushroom Alarm")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.green)
                Text(isAdding ? "新增蘑菇" : "蘑菇鬧鐘")
                    .font(.system(size: 28, weight: .black))
            }
            Spacer()
            if !mushrooms.isEmpty {
                Button { isAdding = true } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.heavy))
                        .frame(width: 48, height: 48)
                        .background(Color.green, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
                }
                .accessibilityLabel("新增蘑菇鬧鐘")
            }
        }
    }

    private func carouselDots(selectedID: UUID) -> some View {
        HStack(spacing: 6) {
            ForEach(mushrooms) { mushroom in
                Capsule()
                    .fill(mushroom.id == selectedID ? Color.green : Color(.systemGray3))
                    .frame(width: mushroom.id == selectedID ? 28 : 8, height: 8)
                    .animation(.spring, value: selectedID)
                    .onTapGesture { activeID = mushroom.id }
                    .accessibilityLabel("切換到 \(mushroom.location)")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var reminderRows: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("刷新通知節奏")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("滑動切換蘑菇")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.green)
            }
            // Same slice as the JSX mockup: indices 1..<5 (skip "finished" and "respawn").
            ForEach(Array(NotificationOffset.allCases.dropFirst().dropLast().enumerated()), id: \.element.id) { index, offset in
                ReminderRowView(index: index, offset: offset)
            }
        }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0xE7F8D1), Color(hex: 0xD1FAE5), Color(hex: 0xE0F2FE)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct ReminderRowView: View {
    let index: Int
    let offset: NotificationOffset

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index + 1)")
                .font(.subheadline.weight(.black))
                .frame(width: 36, height: 36)
                .background(Color.green.opacity(0.18), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(offset.label)
                    .font(.subheadline.weight(.bold))
                Text("\(offset.offsetLabel) · \(offset.tone)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct EmptyStateView: View {
    var onOpenAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("🍄")
                .font(.system(size: 56))
                .frame(width: 96, height: 96)
                .background(Color.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 28))
            Text("目前沒有鬧鐘")
                .font(.title.weight(.black))
            Text("新增 Pikmin 截圖後，會自動建立蘑菇倒數與刷新提醒。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: onOpenAdd) {
                Label("新增蘑菇鬧鐘", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .controlSize(.large)
        }
        .padding(32)
        .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 28))
    }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xff) / 255
        let g = Double((hex >> 8) & 0xff) / 255
        let b = Double(hex & 0xff) / 255
        self.init(red: r, green: g, blue: b)
    }
}
