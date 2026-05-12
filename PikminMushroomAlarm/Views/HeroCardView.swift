// Target: PikminMushroomAlarm
// Mirrors HeroCard in pikmin_alarm_mockup.jsx: big circular timer + finish/respawn.

import SwiftUI

struct HeroCardView: View {
    let mushroom: Mushroom

    // 2 hours, matching MAX_SECONDS in the JSX mockup.
    private let maxSeconds = 7200
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var now: Date = .now

    var body: some View {
        let remaining = max(0, Int(mushroom.finishDate.timeIntervalSince(now)))
        let progress = 1 - min(1, Double(remaining) / Double(maxSeconds))

        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(mushroom.type)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text(mushroom.location)
                        .font(.system(size: 26, weight: .black))
                    Label("Pikmin Bloom Mushroom", systemImage: "mappin.and.ellipse")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green.opacity(0.15), in: Capsule())
                }
                Spacer()
                Text("🍄")
                    .font(.system(size: 28))
                    .padding(12)
                    .background(Color.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
            }

            ZStack {
                Circle().fill(Color.green.opacity(0.12))
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.25), value: progress)
                VStack(spacing: 6) {
                    Text("剩下時間")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text(TimeFormatting.hms(seconds: remaining))
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .monospacedDigit()
                    Text("新蘑菇刷新提醒模式")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                }
            }
            .frame(width: 224, height: 224)
            .frame(maxWidth: .infinity)

            HStack(spacing: 12) {
                infoTile(title: "結束時間", value: TimeFormatting.clock(mushroom.finishDate), tint: .primary)
                infoTile(title: "刷新時間", value: TimeFormatting.clock(mushroom.respawnDate), tint: .green)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.08), radius: 18, y: 8)
        .onReceive(ticker) { now = $0 }
    }

    private func infoTile(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.black))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 18))
    }
}
