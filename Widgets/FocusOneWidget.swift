import WidgetKit
import SwiftUI

struct FocusOneWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetDataSnapshot
}

struct FocusOneWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusOneWidgetEntry {
        FocusOneWidgetEntry(
            date: Date(),
            snapshot: placeholderSnapshot()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FocusOneWidgetEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusOneWidgetEntry>) -> Void) {
        let entry = loadEntry()
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func loadEntry() -> FocusOneWidgetEntry {
        let snapshot = AppGroupStorage.shared.loadWidgetSnapshot() ?? placeholderSnapshot()
        return FocusOneWidgetEntry(date: Date(), snapshot: snapshot)
    }

    private func placeholderSnapshot() -> WidgetDataSnapshot {
        WidgetDataSnapshot(
            habitName: "Focus",
            iconSymbol: "sparkles",
            currentStreak: 3,
            doneToday: false,
            themeHex: "34C9A5"
        )
    }
}

struct FocusOneWidgetEntryView: View {
    let entry: FocusOneWidgetProvider.Entry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let accent = Color(widgetHex: entry.snapshot.themeHex)

        switch family {
        case .accessoryCircular:
            ZStack {
                Circle().fill(accent.opacity(0.25))
                VStack(spacing: 1) {
                    Image(systemName: entry.snapshot.doneToday ? "checkmark" : entry.snapshot.iconSymbol)
                        .font(.caption2.weight(.semibold))
                    Text("\(entry.snapshot.currentStreak)")
                        .font(.caption.weight(.bold))
                }
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Image(systemName: entry.snapshot.iconSymbol)
                        .foregroundStyle(accent)
                    Text(entry.snapshot.habitName)
                }
                .font(.caption2)
                .lineLimit(1)
                Text(L10n.streakDays(entry.snapshot.currentStreak))
                    .font(.caption)
                Text(entry.snapshot.doneToday ? L10n.text("widget.done") : L10n.text("widget.not_done"))
                    .font(.caption2)
                    .foregroundStyle(entry.snapshot.doneToday ? accent : .secondary)
            }
        default:
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: entry.snapshot.iconSymbol)
                        .foregroundStyle(accent)
                    Text(entry.snapshot.habitName)
                }
                .font(.headline)
                .lineLimit(1)
                Text(L10n.streakDays(entry.snapshot.currentStreak))
                    .font(.subheadline)
                HStack(spacing: 6) {
                    Image(systemName: entry.snapshot.doneToday ? "checkmark.circle.fill" : "circle")
                    Text(entry.snapshot.doneToday ? L10n.text("widget.done") : L10n.text("widget.not_done"))
                }
                .font(.caption)
                .foregroundStyle(entry.snapshot.doneToday ? accent : .secondary)
            }
            .padding(12)
            .containerBackground(accent.opacity(0.15), for: .widget)
        }
    }
}

struct FocusOneWidget: Widget {
    let kind = "FocusOneWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusOneWidgetProvider()) { entry in
            FocusOneWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(L10n.text("widget.title"))
        .description(L10n.text("widget.description"))
        .supportedFamilies([.systemSmall, .accessoryRectangular, .accessoryCircular])
    }
}

@main
struct FocusOneWidgetBundle: WidgetBundle {
    var body: some Widget {
        FocusOneWidget()
    }
}

private extension Color {
    init(widgetHex hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&int)

        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64

        switch clean.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 52, 201, 165)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
