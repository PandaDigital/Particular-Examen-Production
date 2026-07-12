import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var store: ExamenStore
    @Environment(\.dismiss) private var dismiss
    @State private var schedule = NotificationSchedule()
    @State private var message: String?
    @State private var isSaving = false
    @State private var unlocked = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 9) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundStyle(store.accent)
                                .onTapGesture(count: 3) { unlockSelection() }
                                .accessibilityLabel("Commitment lock")
                            Text(store.data.selectedVice?.rawValue ?? "No vice selected")
                                .font(.headline)
                        }
                        if let end = store.data.commitmentEndDate {
                            Text("Commitment ends \(end.formatted(date: .long, time: .omitted)).")
                                .foregroundStyle(ExamenPalette.secondaryText)
                        }
                        Text("The \(store.data.commitmentDays)-day limit protects the focus of the practice.")
                            .font(.footnote)
                            .foregroundStyle(ExamenPalette.quietText)
                    }
                    .padding(.vertical, 5)
                } header: {
                    Text("Chosen vice")
                }

                Section {
                    NotificationTimeRow(
                        title: "Morning resolve",
                        systemImage: "sunrise.fill",
                        enabled: $schedule.morningEnabled,
                        hour: $schedule.morningHour,
                        minute: $schedule.morningMinute
                    )
                    NotificationTimeRow(
                        title: "Midday count",
                        systemImage: "sun.max.fill",
                        enabled: $schedule.middayEnabled,
                        hour: $schedule.middayHour,
                        minute: $schedule.middayMinute
                    )
                    NotificationTimeRow(
                        title: "Evening count",
                        systemImage: "moon.stars.fill",
                        enabled: $schedule.eveningEnabled,
                        hour: $schedule.eveningHour,
                        minute: $schedule.eveningMinute
                    )

                    Button {
                        saveNotifications()
                    } label: {
                        HStack {
                            Text(isSaving ? "Saving…" : "Save notification schedule")
                            Spacer()
                            if isSaving { ProgressView() }
                        }
                    }
                    .disabled(isSaving)
                } header: {
                    Text("Alert times")
                } footer: {
                    Text("Choose each time, enable the reminders you want, then save. Time Sensitive delivery can break through Focus when your iOS settings allow it.")
                }

                Section {
                    Label("Long-press the app icon and choose Record a Fall for quick entry.", systemImage: "hand.tap")
                    Label("Add a widget for one-tap recording and your weekly streak.", systemImage: "square.grid.2x2")
                } header: {
                    Text("Quick recording")
                }

                if let message {
                    Section {
                        Text(message)
                            .foregroundStyle(message.hasPrefix("Saved") || unlocked ? store.accent : Color(hex: "FF9B91"))
                    }
                }

                Section {
                    Text("Particular Examen stores your entries on this device and in its shared widget container. It does not require an account or transmit your spiritual record.")
                        .font(.footnote)
                        .foregroundStyle(ExamenPalette.secondaryText)
                } header: {
                    Text("Privacy")
                }
            }
            .scrollContentBackground(.hidden)
            .background(ExamenPalette.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { schedule = store.data.notifications }
        }
        .preferredColorScheme(.dark)
    }

    private func saveNotifications() {
        isSaving = true
        message = nil
        Task {
            do {
                try await NotificationManager.requestPermissionAndSchedule(schedule)
                await MainActor.run {
                    store.updateNotifications(schedule)
                    message = "Saved. Your three-part rhythm is ready."
                    isSaving = false
                }
            } catch {
                await MainActor.run {
                    message = error.localizedDescription
                    isSaving = false
                }
            }
        }
    }

    private func unlockSelection() {
        guard !store.data.mayChooseVice else { return }
        store.unlockViceSelection()
        unlocked = true
        message = "The commitment lock is open. Return to the dashboard to choose again."
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

struct NotificationTimeRow: View {
    let title: String
    let systemImage: String
    @Binding var enabled: Bool
    @Binding var hour: Int
    @Binding var minute: Int

    private var time: Binding<Date> {
        Binding {
            Calendar.current.date(
                bySettingHour: hour,
                minute: minute,
                second: 0,
                of: Date()
            ) ?? Date()
        } set: { date in
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            hour = components.hour ?? hour
            minute = components.minute ?? minute
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Toggle(isOn: $enabled) {
                Label(title, systemImage: systemImage)
                    .font(.headline)
            }
            .tint(ExamenPalette.defaultAccent)

            HStack {
                Text("Alert time")
                    .font(.subheadline)
                    .foregroundStyle(ExamenPalette.secondaryText)
                Spacer()
                DatePicker(
                    "Select \(title) time",
                    selection: time,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .datePickerStyle(.compact)
            }
        }
        .padding(.vertical, 7)
    }
}
