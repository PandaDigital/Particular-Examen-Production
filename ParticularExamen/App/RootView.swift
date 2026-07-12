import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: ExamenStore

    var body: some View {
        Group {
            if store.data.selectedVice == nil {
                IntroductionView()
            } else {
                DashboardView()
            }
        }
        .tint(store.accent)
        .background(ExamenPalette.background.ignoresSafeArea())
    }
}

struct IntroductionView: View {
    @EnvironmentObject private var store: ExamenStore
    @State private var showingSelection = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    BrandHeader(kicker: "A FOCUSED CAMPAIGN", title: "Particular\nExamen")

                    VStack(alignment: .leading, spacing: 15) {
                        Text("YOU KNOW THE FAULT\nTHAT KEEPS RETURNING.")
                            .font(.system(size: 28, weight: .black, design: .serif))
                            .tracking(0.5)
                            .foregroundStyle(ExamenPalette.text)

                        Text("Not merely the list you repeat in confession, but the habit beneath it—the one excused so often that it has begun to feel permanent.")
                        Text("Saint Ignatius of Loyola offered a discipline for bringing one fault into the light and holding it there, day after day, until grace and practice loosen its hold.")
                        Text("This is the Particular Examen: not a general review of everything, but a focused campaign against one vice. Holiness is not a passing feeling. It is fidelity made concrete—one choice, one count, one day at a time.")
                    }
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .foregroundStyle(ExamenPalette.secondaryText)
                    .lineSpacing(6)

                    Button {
                        showingSelection = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("CHOOSE ONE VICE")
                                    .font(.caption.weight(.bold))
                                    .tracking(1.8)
                                Text("Choose your commitment")
                                    .font(.system(size: 20, weight: .bold, design: .serif))
                            }
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.title3.weight(.semibold))
                        }
                        .foregroundStyle(ExamenPalette.background)
                        .padding(20)
                        .background(ExamenPalette.defaultAccent, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .accessibilityHint("Opens the list of seven capital vices")
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 24)
            }
            .background(ExamenPalette.background)
            .sheet(isPresented: $showingSelection) {
                ViceSelectionView()
                    .environmentObject(store)
            }
        }
    }
}

struct ViceSelectionView: View {
    @EnvironmentObject private var store: ExamenStore
    @Environment(\.dismiss) private var dismiss
    @State private var pendingVice: Vice?
    @State private var commitmentDays = 90

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Choose the single fault you will watch, count, and resist. Then choose how long you will hold the commitment.")
                        .font(.system(size: 17, design: .serif))
                        .foregroundStyle(ExamenPalette.secondaryText)
                        .lineSpacing(5)
                        .padding(.bottom, 4)

                    CommitmentLengthPicker(selection: $commitmentDays)
                        .padding(.bottom, 6)

                    ForEach(Vice.allCases) { vice in
                        Button { pendingVice = vice } label: {
                            ViceCard(vice: vice)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(vice.rawValue). \(vice.definition)")
                    }
                }
                .padding(20)
            }
            .background(ExamenPalette.background)
            .navigationTitle("Select a vice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if store.data.selectedVice != nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
            .confirmationDialog(
                "Commit to \(pendingVice?.rawValue ?? "this vice") for \(commitmentDays) days?",
                isPresented: Binding(
                    get: { pendingVice != nil },
                    set: { if !$0 { pendingVice = nil } }
                ),
                titleVisibility: .visible
            ) {
                if let vice = pendingVice {
                    Button("Begin with \(vice.rawValue)") {
                        store.choose(vice, commitmentDays: commitmentDays)
                        dismiss()
                    }
                }
                Button("Keep discerning", role: .cancel) { pendingVice = nil }
            } message: {
                Text("A focused practice grows through constancy. This choice cannot ordinarily be changed before the commitment ends.")
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct CommitmentLengthPicker: View {
    @Binding var selection: Int
    private let choices = [30, 60, 90]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("COMMITMENT LENGTH")
                .font(.caption.weight(.bold))
                .tracking(1.7)
                .foregroundStyle(ExamenPalette.defaultAccent)

            HStack(spacing: 9) {
                ForEach(choices, id: \.self) { days in
                    Button {
                        selection = days
                    } label: {
                        VStack(spacing: 2) {
                            Text("\(days)")
                                .font(.title3.weight(.bold))
                            Text("DAYS")
                                .font(.caption2.weight(.bold))
                                .tracking(1)
                        }
                        .foregroundStyle(selection == days ? ExamenPalette.background : ExamenPalette.text)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(
                            selection == days ? ExamenPalette.defaultAccent : ExamenPalette.raised,
                            in: RoundedRectangle(cornerRadius: 13)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 13)
                                .stroke(ExamenPalette.defaultAccent.opacity(selection == days ? 1 : 0.4), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(days) day commitment")
                    .accessibilityAddTraits(selection == days ? .isSelected : [])
                }
            }
        }
        .padding(16)
        .background(ExamenPalette.surface, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct ViceCard: View {
    let vice: Vice

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: vice.symbol)
                .font(.title2)
                .foregroundStyle(vice.color)
                .frame(width: 46, height: 46)
                .background(vice.color.opacity(0.14), in: RoundedRectangle(cornerRadius: 13))

            VStack(alignment: .leading, spacing: 5) {
                Text(vice.rawValue)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(vice.color)
                Text(vice.definition)
                    .font(.subheadline)
                    .foregroundStyle(ExamenPalette.secondaryText)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .foregroundStyle(ExamenPalette.quietText)
        }
        .padding(17)
        .background(ExamenPalette.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(vice.color.opacity(0.55), lineWidth: 1)
        }
    }
}

struct BrandHeader: View {
    let kicker: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "scope")
                .font(.system(size: 27, weight: .light))
                .foregroundStyle(ExamenPalette.defaultAccent)
            Text(kicker)
                .font(.caption.weight(.bold))
                .tracking(2.2)
                .foregroundStyle(ExamenPalette.defaultAccent)
            Text(title)
                .font(.system(size: 52, weight: .bold, design: .serif))
                .foregroundStyle(ExamenPalette.text)
                .minimumScaleFactor(0.8)
                .lineSpacing(-7)
        }
    }
}
