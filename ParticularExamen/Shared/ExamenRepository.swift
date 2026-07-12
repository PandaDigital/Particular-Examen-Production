import Foundation
import WidgetKit

enum ExamenRepository {
    static let suiteName = "group.com.philreichner.ParticularExamen"
    static let dataKey = "particularExamen.data.v1"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    static func load() -> ExamenData {
        guard let payload = defaults.data(forKey: dataKey),
              let decoded = try? JSONDecoder().decode(ExamenData.self, from: payload)
        else { return ExamenData() }
        return decoded
    }

    static func save(_ data: ExamenData) {
        guard let payload = try? JSONEncoder().encode(data) else { return }
        defaults.set(payload, forKey: dataKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    @discardableResult
    static func addFall(at date: Date = Date()) -> ExamenData {
        var data = load()
        let day = Calendar.current.startOfDay(for: date)
        if let index = data.records.firstIndex(where: { Calendar.current.isDate($0.day, inSameDayAs: day) }) {
            data.records[index].fallDates.append(date)
        } else {
            data.records.append(DayRecord(day: day, fallDates: [date]))
        }
        save(data)
        NotificationCenter.default.post(name: .examenDataDidChange, object: nil)
        return data
    }
}

extension Notification.Name {
    static let examenDataDidChange = Notification.Name("examenDataDidChange")
}
