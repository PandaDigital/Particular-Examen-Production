import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: ExamenStore
    @State private var selectedSheet: Sheet?

    enum Sheet: Identifiable {
        case method, settings, viceSelection
        var id: Self { self }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    dashboardHeader
                    FallCounterCard()
                    DailyMethodCard()
                    WeekTracker(data: store.data, accent: store.accent)
                    FallHistoryCard(data: store.data, accent: store.accent)
                    commitmentCard
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 32)
            }
            .background(ExamenPalette.background)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { selectedSheet = .method } label: {
                        Label("The method", systemImage: "book.closed")
                    }
                    .accessibilityLabel("Read the method")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { selectedSheet = .settings } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .sheet(item: $selectedSheet) { sheet in
                switch sheet {
                case .method: MethodView().environmentObject(store)
                case .settings: SettingsView().environmentObject(store)
                case .viceSelection: ViceSelectionView().environmentObject(store)
                }
            }
        }
    }

    private var dashboardHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 5) {
                Text("PARTICULAR EXAMEN")
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(store.accent)
                Text(store.data.selectedVice?.rawValue ?? "Examen")
                    .font(.system(size: 42, weight: .bold, design: .serif))
                    .foregroundStyle(ExamenPalette.text)
            }
            Spacer()
            Image(systemName: store.data.selectedVice?.symbol ?? "scope")
                .font(.system(size: 32))
                .foregroundStyle(store.accent)
                .padding(.bottom, 4)
        }
        .padding(.top, 20)
    }

    private var commitmentCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label("THE \(store.data.commitmentDays)-DAY COMMITMENT", systemImage: "lock.shield.fill")
                .font(.caption.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(store.accent)
            if let end = store.data.commitmentEndDate {
                Text(store.data.mayChooseVice ? "Your vice selection is available." : "Held until \(end.formatted(date: .abbreviated, time: .omitted))")
                    .font(.headline)
                    .foregroundStyle(ExamenPalette.text)
            }
            Text("Constancy gives the practice time to expose patterns that enthusiasm alone cannot change.")
                .font(.subheadline)
                .foregroundStyle(ExamenPalette.secondaryText)
            if store.data.mayChooseVice {
                Button("Choose a different vice") { selectedSheet = .viceSelection }
                    .font(.subheadline.weight(.bold))
                    .padding(.top, 3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(ExamenPalette.surface, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct FallHistoryCard: View {
    let data: ExamenData
    let accent: Color

    private var recentDays: [(date: Date, falls: Int)] {
        data.recentDailyFalls(numberOfDays: 7)
    }

    private var highestRecentCount: Int {
        max(1, recentDays.map(\.falls).max() ?? 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("LOOK BACK")
                    .font(.caption.weight(.bold))
                    .tracking(1.7)
                    .foregroundStyle(accent)
                Spacer()
                Label("On this device", systemImage: "lock.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(ExamenPalette.quietText)
            }

            HStack(spacing: 10) {
                FallAverageMetric(
                    title: "7-DAY AVERAGE",
                    average: data.averageFalls(overLast: 7),
                    accent: accent
                )
                FallAverageMetric(
                    title: "30-DAY AVERAGE",
                    average: data.averageFalls(overLast: 30),
                    accent: accent
                )
            }

            Divider().overlay(accent.opacity(0.3))

            Text("DAILY FALLS")
                .font(.caption2.weight(.bold))
                .tracking(1.3)
                .foregroundStyle(ExamenPalette.secondaryText)

            HStack(alignment: .bottom, spacing: 7) {
                ForEach(recentDays, id: \.date) { item in
                    VStack(spacing: 6) {
                        Text("\(item.falls)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(item.falls == 0 ? ExamenPalette.quietText : ExamenPalette.text)
                        VStack {
                            Spacer(minLength: 0)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.falls == 0 ? ExamenPalette.raised : accent)
                                .frame(height: barHeight(for: item.falls))
                        }
                        .frame(height: 48)
                        Text(item.date.formatted(.dateTime.weekday(.narrow)))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(ExamenPalette.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(item.date.formatted(.dateTime.weekday(.wide))), \(item.falls) falls")
                }
            }

            Text("Averages include only days when all three movements of the Examen were completed.")
                .font(.caption)
                .foregroundStyle(ExamenPalette.quietText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(ExamenPalette.surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20).stroke(accent.opacity(0.45), lineWidth: 1)
        }
    }

    private func barHeight(for falls: Int) -> CGFloat {
        guard falls > 0 else { return 4 }
        return max(8, 48 * CGFloat(falls) / CGFloat(highestRecentCount))
    }
}

struct FallAverageMetric: View {
    let title: String
    let average: Double
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption2.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(ExamenPalette.secondaryText)
            Text(average.formatted(.number.precision(.fractionLength(1))))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(accent)
            Text("falls / day")
                .font(.caption)
                .foregroundStyle(ExamenPalette.quietText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(ExamenPalette.raised, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct FallCounterCard: View {
    @EnvironmentObject private var store: ExamenStore
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 12) {
            Text("FALLS TODAY")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(ExamenPalette.secondaryText)

            Button {
                store.recordFall()
                withAnimation(.spring(response: 0.24, dampingFraction: 0.55)) { pulse.toggle() }
            } label: {
                ZStack {
                    Circle()
                        .fill(store.accent.opacity(0.12))
                    Circle()
                        .stroke(store.accent, lineWidth: 2)
                    VStack(spacing: 3) {
                        Text("\(store.today.totalFalls)")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                        Text("TAP TO RECORD")
                            .font(.caption2.weight(.bold))
                            .tracking(1.3)
                    }
                    .foregroundStyle(ExamenPalette.text)
                }
                .frame(width: 176, height: 176)
                .scaleEffect(pulse ? 1.035 : 1)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Record a fall. \(store.today.totalFalls) falls today")
            .accessibilityHint("Adds one to today’s count")

            Button {
                store.removeLastFall()
            } label: {
                Label("Undo last", systemImage: "arrow.uturn.backward")
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(ExamenPalette.secondaryText)
            .disabled(store.today.totalFalls == 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(ExamenPalette.surface, in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(store.accent.opacity(0.45), lineWidth: 1)
        }
    }
}

struct DailyMethodCard: View {
    @EnvironmentObject private var store: ExamenStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TODAY’S THREE MOVEMENTS")
                .font(.caption.weight(.bold))
                .tracking(1.7)
                .foregroundStyle(store.accent)
                .padding(.bottom, 12)

            PhaseRow(
                number: "I",
                title: "Morning resolve",
                detail: "Name the fault and ask for grace.",
                completed: store.today.morningResolved,
                accent: store.accent,
                action: store.completeMorning
            )
            Divider().overlay(Color.white.opacity(0.12))
            PhaseRow(
                number: "II",
                title: "Midday count",
                detail: store.today.middayCompleted
                    ? "Morning: \(store.today.morningFalls ?? 0) falls"
                    : "Count the falls since morning.",
                completed: store.today.middayCompleted,
                accent: store.accent,
                action: store.completeMidday
            )
            Divider().overlay(Color.white.opacity(0.12))
            PhaseRow(
                number: "III",
                title: "Evening count",
                detail: store.today.eveningCompleted
                    ? "Afternoon: \(store.today.afternoonFalls ?? 0) falls"
                    : "Count again and compare the lines.",
                completed: store.today.eveningCompleted,
                accent: store.accent,
                action: store.completeEvening
            )
        }
        .padding(18)
        .background(ExamenPalette.surface, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct PhaseRow: View {
    let number: String
    let title: String
    let detail: String
    let completed: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        HStack(spacing: 13) {
            Text(number)
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundStyle(accent)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(ExamenPalette.text)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(ExamenPalette.secondaryText)
            }
            Spacer(minLength: 8)
            Button(action: action) {
                Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(completed ? accent : ExamenPalette.quietText)
            }
            .buttonStyle(.plain)
            .disabled(completed)
            .accessibilityLabel(completed ? "\(title) completed" : "Complete \(title)")
        }
        .padding(.vertical, 13)
    }
}

struct WeekTracker: View {
    let data: ExamenData
    let accent: Color
    private let calendar = Calendar.current

    private var days: [Date] {
        let today = calendar.startOfDay(for: Date())
        return (-6...0).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("LAST SEVEN DAYS")
                    .font(.caption.weight(.bold))
                    .tracking(1.6)
                    .foregroundStyle(ExamenPalette.secondaryText)
                Spacer()
                Text("\(data.currentStreak) day streak")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accent)
            }
            HStack {
                ForEach(days, id: \.self) { day in
                    VStack(spacing: 8) {
                        Text(day.formatted(.dateTime.weekday(.narrow)))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(ExamenPalette.secondaryText)
                        ZStack {
                            Circle().stroke(ExamenPalette.quietText.opacity(0.65), lineWidth: 2)
                            if data.record(for: day)?.isComplete == true {
                                Circle().fill(accent)
                                Image(systemName: "checkmark")
                                    .font(.caption2.weight(.black))
                                    .foregroundStyle(ExamenPalette.background)
                            }
                        }
                        .frame(width: 29, height: 29)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            Divider().overlay(accent.opacity(0.35))
            HStack {
                Text("Total: \(data.totalCompletedDays) days")
                Spacer()
                Text("Streak: \(data.currentStreak) days")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(ExamenPalette.secondaryText)
        }
        .padding(18)
        .background(ExamenPalette.surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20).stroke(accent.opacity(0.45), lineWidth: 1)
        }
    }
}
