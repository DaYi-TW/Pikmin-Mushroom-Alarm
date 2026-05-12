// Target: PikminWidgets
// Lock screen banner + Dynamic Island for one Mushroom timer.
//
// Text(timerInterval:) gives a free, smooth, per-second countdown without
// having to push state updates every second — ActivityKit would throttle us
// anyway. We just hand it the finish/respawn dates and let SwiftUI tick.

import SwiftUI
import WidgetKit
import ActivityKit

struct MushroomLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MushroomActivityAttributes.self) { context in
            LockScreenView(context: context)
                .activityBackgroundTint(Color.green.opacity(0.15))
                .activitySystemActionForegroundColor(.green)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded — when the user long-presses or after a tap.
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.attributes.location)
                            .font(.caption.weight(.bold))
                            .lineLimit(1)
                    } icon: {
                        Text("🍄")
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    countdown(for: context, font: .title3)
                        .foregroundStyle(.green)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.attributes.type)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("刷新 \(context.state.respawnDate, style: .time)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.green)
                    }
                }
            } compactLeading: {
                Text("🍄")
            } compactTrailing: {
                countdown(for: context, font: .caption.weight(.bold))
                    .foregroundStyle(.green)
            } minimal: {
                Text("🍄")
            }
            .keylineTint(.green)
        }
    }

    // Choose what to count down to: finish first, then respawn.
    private func countdown(
        for context: ActivityViewContext<MushroomActivityAttributes>,
        font: Font
    ) -> some View {
        let now = Date.now
        let target = now < context.state.finishDate ? context.state.finishDate : context.state.respawnDate
        return Text(timerInterval: now...target, countsDown: true)
            .font(font)
            .monospacedDigit()
    }
}

private struct LockScreenView: View {
    let context: ActivityViewContext<MushroomActivityAttributes>

    var body: some View {
        let now = Date.now
        let isAwaitingRespawn = now >= context.state.finishDate
        let target = isAwaitingRespawn ? context.state.respawnDate : context.state.finishDate
        let label = isAwaitingRespawn ? "刷新倒數" : "剩下時間"

        HStack(spacing: 16) {
            Text("🍄")
                .font(.system(size: 36))
                .frame(width: 56, height: 56)
                .background(Color.green.opacity(0.18), in: RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.location)
                    .font(.headline)
                    .lineLimit(1)
                Text(context.attributes.type)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(timerInterval: now...target, countsDown: true)
                    .font(.title2.weight(.black))
                    .monospacedDigit()
                    .foregroundStyle(isAwaitingRespawn ? .green : .primary)
            }
        }
        .padding(16)
    }
}
