import Foundation
import SwiftUI

@MainActor
final class ExamenStore: ObservableObject {
    @Published private(set) var data: ExamenData

    init() {
        data = ExamenRepository.load()
        NotificationCenter.default.addObserver(
            forName: .examenDataDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.reload() }
        }
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    var today: DayRecord {
        data.record(for: Date()) ?? DayRecord(day: Calendar.current.startOfDay(for: Date()))
    }

    var accent: Color { data.selectedVice?.color ?? ExamenPalette.defaultAccent }

    func reload() { data = ExamenRepository.load() }

    func choose(_ vice: Vice, commitmentDays: Int) {
        guard data.selectedVice == nil || data.mayChooseVice else { return }
        data.selectedVice = vice
        data.selectedAt = Date()
        data.commitmentDays = [30, 60, 90].contains(commitmentDays) ? commitmentDays : 90
        data.overrideUnlocked = false
        persist()
    }

    func unlockViceSelection() {
        data.overrideUnlocked = true
        persist()
    }

    func recordFall() {
        data = ExamenRepository.addFall()
    }

    func removeLastFall() {
        updateToday { record in
            guard !record.fallDates.isEmpty else { return }
            record.fallDates.removeLast()
        }
    }

    func completeMorning(on date: Date = Date()) {
        updateDay(date) { $0.morningResolved = true }
    }

    func completeMidday(on date: Date = Date()) {
        let calendar = Calendar.current
        let cutoff = calendar.date(bySettingHour: data.notifications.middayHour,
                                   minute: data.notifications.middayMinute, second: 0, of: date) ?? date
        updateDay(date) {
            guard !$0.middayCompleted else { return }
            $0.middayCompleted = true
            $0.morningFalls = calendar.isDateInToday(date)
                ? $0.totalFalls
                : $0.fallDates.filter { $0 < cutoff }.count
            if $0.eveningCompleted {
                $0.afternoonFalls = max(0, $0.totalFalls - ($0.morningFalls ?? 0))
            }
        }
    }

    func completeEvening(on date: Date = Date()) {
        updateDay(date) {
            guard !$0.eveningCompleted else { return }
            $0.eveningCompleted = true
            let morning = $0.morningFalls ?? 0
            $0.afternoonFalls = max(0, $0.totalFalls - morning)
        }
    }

    func updateNotifications(_ schedule: NotificationSchedule) {
        data.notifications = schedule
        persist()
    }

    private func updateToday(_ change: (inout DayRecord) -> Void) {
        updateDay(Date(), change)
    }

    private func updateDay(_ date: Date, _ change: (inout DayRecord) -> Void) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let day = calendar.startOfDay(for: date)
        guard day <= today else { return }
        if let index = data.records.firstIndex(where: { Calendar.current.isDate($0.day, inSameDayAs: day) }) {
            change(&data.records[index])
        } else {
            var record = DayRecord(day: day)
            change(&record)
            data.records.append(record)
        }
        persist()
    }

    private func persist() {
        ExamenRepository.save(data)
        objectWillChange.send()
    }
}
