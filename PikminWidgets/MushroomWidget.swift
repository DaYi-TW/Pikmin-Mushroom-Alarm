// Target: PikminWidgets
// Home Screen widget that reads from the shared SwiftData store.
//
// Strategy: instead of refreshing every second (impossible — WidgetKit budgets
// timeline refreshes), we generate one entry per upcoming "interesting" moment
// (finish, respawn) and let Text(timerInterval:) smoothly tick between them.

import SwiftUI
import WidgetKit
import SwiftData

struct MushroomWidget: Widget {
    let kind = "MushroomWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MushroomTimelineProvider()) { entry in
            MushroomWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("蘑菇鬧鐘")
        .description("顯示最接近刷新的蘑菇倒數。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MushroomEntry: TimelineEntry {
    var date: Date
    var soonest: MushroomSnapshot?
    var others: [MushroomSnapshot]
}

struct MushroomSnapshot: Hashable {
    var location: String
    var type: String
    var finishDate: Date
    var respawnDate: Date
}

struct MushroomTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> MushroomEntry {
        MushroomEntry(
            date: .now,
            soonest: MushroomSnapshot(
                location: "功夫壁畫",
                type: "一般 輝煌蘑菇",
                finishDate: .now.addingTimeInterval(3613),
                respawnDate: .now.addingTimeInterval(3913)
            ),
            others: []
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MushroomEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MushroomEntry>) -> Void) {
        let entry = currentEntry()
        // Schedule the next refresh at the next interesting moment, or in 15 minutes
        // (so newly-added mushrooms appear without waiting too long).
        let nextRefresh: Date = {
            let candidates = ([entry.soonest] + entry.others.map { Optional($0) })
                .compactMap { $0 }
                .flatMap { [$0.finishDate, $0.respawnDate] }
                .filter { $0 > .now }
            return candidates.min() ?? .now.addingTimeInterval(15 * 60)
        }()
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func currentEntry() -> MushroomEntry {
        let snapshots = loadSnapshots()
        let upcoming = snapshots
            .filter { $0.respawnDate > .now }
            .sorted { $0.respawnDate < $1.respawnDate }
        return MushroomEntry(date: .now, soonest: upcoming.first, others: Array(upcoming.dropFirst()))
    }

    private func loadSnapshots() -> [MushroomSnapshot] {
        let schema = Schema([Mushroom.self])
        guard let url = AppGroup.storeURL else { return [] }
        let config = ModelConfiguration(schema: schema, url: url)
        guard let container = try? ModelContainer(for: schema, configurations: [config]) else { return [] }
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Mushroom>(sortBy: [SortDescriptor(\.respawnDate)])
        guard let mushrooms = try? context.fetch(descriptor) else { return [] }
        return mushrooms.map {
            MushroomSnapshot(
                location: $0.location,
                type: $0.type,
                finishDate: $0.finishDate,
                respawnDate: $0.respawnDate
            )
        }
    }
}

struct MushroomWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MushroomEntry

    var body: some View {
        switch family {
        case .systemSmall: smallView
        default: mediumView
        }
    }

    private var smallView: some View {
        Group {
            if let snapshot = entry.soonest {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("🍄").font(.title2)
                        Spacer()
                        Text("刷新")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.green)
                    }
                    Spacer(minLength: 0)
                    Text(snapshot.location)
                        .font(.caption.weight(.bold))
                        .lineLimit(1)
                    Text(timerInterval: .now...countdownTarget(for: snapshot), countsDown: true)
                        .font(.title2.weight(.black))
                        .monospacedDigit()
                        .foregroundStyle(.green)
                }
            } else {
                emptyView
            }
        }
    }

    private var mediumView: some View {
        Group {
            if let soonest = entry.soonest {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("🍄")
                            Text(soonest.location)
                                .font(.headline)
                                .lineLimit(1)
                        }
                        Text(soonest.type)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text(timerInterval: .now...countdownTarget(for: soonest), countsDown: true)
                            .font(.title.weight(.black))
                            .monospacedDigit()
                            .foregroundStyle(.green)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if !entry.others.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 6) {
                            Text("接下來")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.secondary)
                            ForEach(entry.others.prefix(3), id: \.self) { other in
                                HStack {
                                    Text(other.location)
                                        .font(.caption)
                                        .lineLimit(1)
                                    Spacer()
                                    Text(timerInterval: .now...countdownTarget(for: other), countsDown: true)
                                        .font(.caption.weight(.bold))
                                        .monospacedDigit()
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        .frame(maxWidth: 140, alignment: .leading)
                    }
                }
            } else {
                emptyView
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 6) {
            Text("🍄").font(.largeTitle)
            Text("沒有蘑菇鬧鐘")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func countdownTarget(for snapshot: MushroomSnapshot) -> Date {
        Date.now < snapshot.finishDate ? snapshot.finishDate : snapshot.respawnDate
    }
}
