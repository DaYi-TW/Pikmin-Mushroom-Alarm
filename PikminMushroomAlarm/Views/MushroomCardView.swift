// Target: PikminMushroomAlarm
// Mirrors MushroomCard in pikmin_alarm_mockup.jsx (carousel item).

import SwiftUI

struct MushroomCardView: View {
    let mushroom: Mushroom
    let isActive: Bool
    var onSelect: () -> Void
    var onRequestDelete: () -> Void
    var onRequestEdit: () -> Void

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var now: Date = .now

    var body: some View {
        let remaining = max(0, Int(mushroom.finishDate.timeIntervalSince(now)))

        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Text("🍄")
                        .font(.system(size: 24))
                        .frame(width: 44, height: 44)
                        .background(Color.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mushroom.location)
                            .font(.subheadline.weight(.black))
                            .lineLimit(1)
                        Text(mushroom.type)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }

                Text(TimeFormatting.hms(seconds: remaining))
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .monospacedDigit()

                HStack {
                    Text("結束 \(TimeFormatting.clock(mushroom.finishDate))")
                    Spacer()
                    Text("刷新 \(TimeFormatting.clock(mushroom.respawnDate))")
                        .foregroundStyle(.green)
                        .fontWeight(.bold)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(width: 240, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(isActive ? Color.green.opacity(0.15) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(isActive ? Color.green : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 6) {
                Button(action: onRequestEdit) {
                    Image(systemName: "pencil")
                        .font(.caption.weight(.heavy))
                        .frame(width: 28, height: 28)
                        .background(Color(.systemGray6), in: Circle())
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("編輯 \(mushroom.location)")

                Button(action: onRequestDelete) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.heavy))
                        .frame(width: 28, height: 28)
                        .background(Color(.systemGray6), in: Circle())
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("刪除 \(mushroom.location)")
            }
            .padding(10)
        }
        .contextMenu {
            Button { onRequestEdit() } label: {
                Label("編輯", systemImage: "pencil")
            }
            Button(role: .destructive) { onRequestDelete() } label: {
                Label("刪除", systemImage: "trash")
            }
        }
        .onReceive(ticker) { now = $0 }
    }
}
