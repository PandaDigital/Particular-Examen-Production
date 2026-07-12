import SwiftUI
import WidgetKit

struct ExamenWidgetEntry: TimelineEntry {
    let date: Date
    let data: ExamenData
}

struct ExamenTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ExamenWidgetEntry {
        var data = ExamenData(selectedVice: .anger, selectedAt: Date())
        data.records = [DayRecord(day: Date(), fallDates: [Date()])]
        return ExamenWidgetEntry(date: Date(), data: data)
    }

    func getSnapshot(in context: Context, completion: @escaping (ExamenWidgetEntry) -> Void) {
        completion(ExamenWidgetEntry(date: Date(), data: ExamenRepository.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ExamenWidgetEntry>) -> Void) {
        let entry = ExamenWidgetEntry(date: Date(), data: ExamenRepository.load())
        let nextMidnight = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }
}

struct ParticularExamenWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ExamenWidgetEntry

    private var accent: Color {
        entry.data.selectedVice?.color ?? ExamenPalette.defaultAccent
    }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallExamenWidget(data: entry.data, accent: accent)
            case .systemMedium:
                MediumExamenWidget(data: entry.data, accent: accent)
            default:
                LargeExamenWidget(data: entry.data, accent: accent)
            }
        }
        .containerBackground(for: .widget) { ExamenPalette.background }
    }
}

struct SmallExamenWidget: View {
    let data: ExamenData
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: data.selectedVice?.symbol ?? "scope")
                    .foregroundStyle(accent)
                Spacer()
                Text("Examen")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ExamenPalette.secondaryText)
            }
            Spacer()
            HStack(alignment: .lastTextBaseline) {
                Text("\(data.record(for: Date())?.totalFalls ?? 0)")
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundStyle(ExamenPalette.text)
                Text("today")
                    .font(.caption)
                    .foregroundStyle(ExamenPalette.secondaryText)
            }
            HStack {
                Text("Record a fall")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(ExamenPalette.secondaryText)
                Spacer()
                Button(intent: RecordFallIntent()) {
                    Image(systemName: "plus")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(ExamenPalette.background)
                        .frame(width: 32, height: 32)
                        .background(accent, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct MediumExamenWidget: View {
    let data: ExamenData
    let accent: Color

    var body: some View {
        HStack(spacing: 18) {
            VStack(alignment: .center, spacing: 6) {
                Text("Examen")
                    .font(.headline)
                    .foregroundStyle(accent)
                    .frame(maxWidth: .infinity)
                Text("\(data.record(for: Date())?.totalFalls ?? 0)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(ExamenPalette.text)
                Text("falls today")
                    .font(.caption)
                    .foregroundStyle(ExamenPalette.secondaryText)
                Spacer(minLength: 0)
                Button(intent: RecordFallIntent()) {
                    Image(systemName: "plus")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(ExamenPalette.background)
                        .frame(width: 32, height: 32)
                        .background(accent, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Record a fall")
            }
            Divider().overlay(accent.opacity(0.4))
            WidgetWeekTracker(data: data, accent: accent)
        }
    }
}

struct LargeExamenWidget: View {
    let data: ExamenData
    let accent: Color

    private var today: DayRecord {
        data.record(for: Date()) ?? DayRecord(day: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("PARTICULAR EXAMEN")
                        .font(.caption2.weight(.bold))
                        .tracking(1.4)
                        .foregroundStyle(ExamenPalette.secondaryText)
                    Text("Examen")
                        .font(.system(size: 27, weight: .bold, design: .serif))
                        .foregroundStyle(accent)
                }
                Spacer()
                Image(systemName: data.selectedVice?.symbol ?? "scope")
                    .font(.title2)
                    .foregroundStyle(accent)
            }

            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(today.totalFalls)")
                        .font(.system(size: 50, weight: .bold, design: .rounded))
                        .foregroundStyle(ExamenPalette.text)
                    Text("falls today")
                        .font(.caption)
                        .foregroundStyle(ExamenPalette.secondaryText)
                }
                Spacer()
                Button(intent: RecordFallIntent()) {
                    Image(systemName: "plus")
                        .font(.title2.weight(.bold))
                    .foregroundStyle(ExamenPalette.background)
                    .frame(width: 72, height: 72)
                    .background(accent, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Record a fall")
            }

            HStack(spacing: 8) {
                WidgetPhase(label: "Morning", complete: today.morningResolved, accent: accent)
                WidgetPhase(label: "Midday", complete: today.middayCompleted, accent: accent)
                WidgetPhase(label: "Evening", complete: today.eveningCompleted, accent: accent)
            }

            Divider().overlay(accent.opacity(0.35))
            WidgetWeekTracker(data: data, accent: accent, expanded: true)
        }
    }
}

struct WidgetPhase: View {
    let label: String
    let complete: Bool
    let accent: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: complete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(complete ? accent : ExamenPalette.quietText)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(ExamenPalette.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(ExamenPalette.surface, in: RoundedRectangle(cornerRadius: 9))
    }
}

struct WidgetWeekTracker: View {
    let data: ExamenData
    let accent: Color
    var expanded = false
    private let calendar = Calendar.current

    private var days: [Date] {
        let today = calendar.startOfDay(for: Date())
        return (-6...0).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: expanded ? 9 : 7) {
            HStack {
                Text("WEEK")
                    .font(.caption2.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(ExamenPalette.secondaryText)
                Spacer()
                Text("\(data.currentStreak) streak")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(accent)
            }
            HStack(spacing: expanded ? 9 : 5) {
                ForEach(days, id: \.self) { day in
                    VStack(spacing: 4) {
                        Text(day.formatted(.dateTime.weekday(.narrow)))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(ExamenPalette.secondaryText)
                        Circle()
                            .fill(data.record(for: day)?.isComplete == true ? accent : .clear)
                            .overlay(Circle().stroke(accent.opacity(0.55), lineWidth: 1.5))
                            .frame(width: expanded ? 22 : 18, height: expanded ? 22 : 18)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            if expanded {
                HStack {
                    Text("Total: \(data.totalCompletedDays) days")
                    Spacer()
                    Text("Streak: \(data.currentStreak) days")
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(ExamenPalette.secondaryText)
            }
        }
    }
}

struct ParticularExamenWidget: Widget {
    let kind = "ParticularExamenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ExamenTimelineProvider()) { entry in
            ParticularExamenWidgetView(entry: entry)
        }
        .configurationDisplayName("Particular Examen")
        .description("Record a fall and keep the three daily movements in view.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
