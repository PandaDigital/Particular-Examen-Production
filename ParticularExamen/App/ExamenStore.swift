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

    func completeMorning() {
        updateToday { $0.morningResolved = true }
    }

    func completeMidday() {
        updateToday {
            $0.middayCompleted = true
            $0.morningFalls = $0.totalFalls
        }
    }

    func completeEvening() {
        updateToday {
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
        let day = Calendar.current.startOfDay(for: Date())
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
