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
            habitName: L10n.text("widget.placeholder_name"),
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
    @Environment(\.colorScheme) private var colorScheme

    private var palette: WidgetPalette {
        WidgetPalette(accent: Color(widgetHex: entry.snapshot.themeHex), colorScheme: colorScheme)
    }

    private var statusSymbol: String {
        entry.snapshot.doneToday ? "checkmark.circle.fill" : "circle"
    }

    private var statusText: String {
        entry.snapshot.doneToday ? L10n.text("widget.state.done") : L10n.text("widget.state.pending")
    }

    private var supportText: String {
        entry.snapshot.doneToday ? L10n.text("widget.support.done") : L10n.text("widget.support.pending")
    }

    private var streakValue: String {
        "\(entry.snapshot.currentStreak)"
    }

    private var streakUnit: String {
        L10n.streakUnit(entry.snapshot.currentStreak)
    }

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
                .containerBackground(for: .widget) { widgetBackground }
        case .systemMedium:
            mediumWidget
                .containerBackground(for: .widget) { widgetBackground }
        case .systemLarge:
            largeWidget
                .containerBackground(for: .widget) { widgetBackground }
        case .accessoryCircular:
            circularAccessory
        case .accessoryRectangular:
            rectangularAccessory
        default:
            smallWidget
                .containerBackground(for: .widget) { widgetBackground }
        }
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            widgetHeader(showsOverline: false)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 4) {
                widgetOverline(L10n.text("widget.current_streak"))

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(streakValue)
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundStyle(palette.primaryText)

                    Text(streakUnit)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(palette.secondaryText)
                }
            }

            widgetStatusPill(compact: false)
        }
        .padding(16)
    }

    private var mediumWidget: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                widgetOverline(L10n.text("widget.current_streak"))

                Spacer(minLength: 0)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(streakValue)
                        .font(.system(size: 58, weight: .heavy, design: .rounded))
                        .foregroundStyle(palette.primaryText)

                    Text(streakUnit)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(palette.secondaryText)
                        .padding(.top, 18)
                }

                Text(supportText)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(palette.secondaryText)
                    .lineLimit(2)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(panelBackground(strength: .accent))

            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    widgetHeader(showsOverline: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(panelBackground(strength: .surface))

                VStack(alignment: .leading, spacing: 8) {
                    widgetOverline(L10n.text("widget.today"))

                    HStack(spacing: 8) {
                        Image(systemName: statusSymbol)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(palette.statusTint(done: entry.snapshot.doneToday))

                        Text(statusText)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(palette.primaryText)
                    }

                    Text(supportText)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(palette.secondaryText)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(14)
                .background(panelBackground(strength: .surface))
            }
            .frame(width: 126)
        }
        .padding(16)
    }

    private var largeWidget: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                widgetHeader(showsOverline: true)

                Spacer(minLength: 0)

                widgetStatusPill(compact: true)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    widgetOverline(L10n.text("widget.current_streak"))

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(streakValue)
                            .font(.system(size: 68, weight: .heavy, design: .rounded))
                            .foregroundStyle(palette.primaryText)

                        Text(streakUnit)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(palette.secondaryText)
                            .padding(.top, 18)
                    }

                    Text(supportText)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(palette.secondaryText)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(18)
                .background(panelBackground(strength: .accent))

                VStack(spacing: 12) {
                    largeInfoCard(
                        title: L10n.text("widget.today"),
                        value: statusText,
                        caption: supportText,
                        symbol: statusSymbol,
                        tint: palette.statusTint(done: entry.snapshot.doneToday)
                    )

                    largeInfoCard(
                        title: L10n.text("widget.current_streak"),
                        value: L10n.streakDays(entry.snapshot.currentStreak),
                        caption: entry.snapshot.habitName,
                        symbol: entry.snapshot.iconSymbol,
                        tint: palette.accent
                    )
                }
                .frame(width: 170)
            }
        }
        .padding(18)
    }

    private var circularAccessory: some View {
        ZStack {
            AccessoryWidgetBackground()

            Circle()
                .fill(palette.accent.opacity(0.18))

            Circle()
                .stroke(palette.accent.opacity(0.32), lineWidth: 5)

            VStack(spacing: 2) {
                Image(systemName: entry.snapshot.doneToday ? "checkmark" : entry.snapshot.iconSymbol)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(palette.accent)

                Text(streakValue)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .padding(4)
        }
    }

    private var rectangularAccessory: some View {
        HStack(spacing: 8) {
            iconBadge(size: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.snapshot.habitName)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .lineLimit(1)

                Text(L10n.streakDays(entry.snapshot.currentStreak))
                    .font(.system(size: 12, weight: .bold, design: .rounded))

                HStack(spacing: 4) {
                    Image(systemName: statusSymbol)
                    Text(statusText)
                }
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(entry.snapshot.doneToday ? palette.accent : .secondary)
            }

            Spacer(minLength: 0)
        }
    }

    private func widgetHeader(showsOverline: Bool) -> some View {
        HStack(spacing: 10) {
            iconBadge(size: 42)

            VStack(alignment: .leading, spacing: 2) {
                if showsOverline {
                    widgetOverline(L10n.text("widget.overline"))
                }

                Text(entry.snapshot.habitName)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.primaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
    }

    private func largeInfoCard(title: String, value: String, caption: String, symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            widgetOverline(title)

            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tint)

                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.primaryText)
                    .lineLimit(2)
            }

            Text(caption)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(palette.secondaryText)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(14)
        .background(panelBackground(strength: .surface))
    }

    private func widgetStatusPill(compact: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: statusSymbol)
            Text(statusText)
                .lineLimit(1)
        }
        .font(.system(size: compact ? 11 : 12, weight: .semibold, design: .rounded))
        .foregroundStyle(palette.statusTint(done: entry.snapshot.doneToday))
        .padding(.horizontal, compact ? 10 : 12)
        .padding(.vertical, compact ? 6 : 8)
        .background(
            Capsule()
                .fill(entry.snapshot.doneToday ? palette.accent.opacity(0.14) : palette.surfaceStrong)
        )
    }

    private func widgetOverline(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(palette.overline)
            .kerning(0.7)
    }

    private func iconBadge(size: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.34, style: .continuous)
                .fill(palette.accent.opacity(0.16))

            Image(systemName: entry.snapshot.doneToday ? "checkmark" : entry.snapshot.iconSymbol)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(palette.accent)
        }
        .frame(width: size, height: size)
    }

    private func panelBackground(strength: WidgetSurfaceStrength) -> some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(strength == .accent ? palette.accentSurface : palette.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(palette.stroke, lineWidth: 1)
            )
    }

    private var widgetBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [palette.backgroundTop, palette.backgroundBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
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
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryCircular])
    }
}

@main
struct FocusOneWidgetBundle: WidgetBundle {
    var body: some Widget {
        FocusOneWidget()
    }
}

private enum WidgetSurfaceStrength {
    case accent
    case surface
}

private struct WidgetPalette {
    let accent: Color
    let colorScheme: ColorScheme

    var accentSurface: Color {
        colorScheme == .dark ? accent.opacity(0.24) : accent.opacity(0.16)
    }

    var surface: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.56)
    }

    var surfaceStrong: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.7)
    }

    var backgroundTop: Color {
        colorScheme == .dark ? Color.black.opacity(0.78) : Color.white.opacity(0.92)
    }

    var backgroundBottom: Color {
        colorScheme == .dark ? accent.opacity(0.22) : accent.opacity(0.12)
    }

    var primaryText: Color {
        colorScheme == .dark ? Color.white : Color.black.opacity(0.88)
    }

    var secondaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.78) : Color.black.opacity(0.55)
    }

    var overline: Color {
        accent.opacity(colorScheme == .dark ? 0.9 : 1)
    }

    var stroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.72)
    }

    func statusTint(done: Bool) -> Color {
        done ? accent : secondaryText
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
