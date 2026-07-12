import Foundation
import SwiftUI

enum Vice: String, Codable, CaseIterable, Identifiable {
    case pride = "Pride"
    case anger = "Anger"
    case envy = "Envy"
    case gluttony = "Gluttony"
    case lust = "Lust"
    case greed = "Greed"
    case sloth = "Sloth"

    var id: String { rawValue }

    var definition: String {
        switch self {
        case .pride: "Placing the self above truth, grace, or the good of another."
        case .anger: "Letting resentment or rage govern judgment, speech, or action."
        case .envy: "Grieving another’s good as though it diminishes your own."
        case .gluttony: "Seeking excess in food, drink, comfort, or consumption."
        case .lust: "Reducing another person to an object of appetite or fantasy."
        case .greed: "Clinging to possessions, status, or security at love’s expense."
        case .sloth: "Resisting the good that love and duty ask of you."
        }
    }

    var symbol: String {
        switch self {
        case .pride: "crown.fill"
        case .anger: "flame.fill"
        case .envy: "eye.fill"
        case .gluttony: "fork.knife"
        case .lust: "heart.fill"
        case .greed: "dollarsign.circle.fill"
        case .sloth: "moon.zzz.fill"
        }
    }

    var hex: String {
        // Every color is used against #101114 at AA-safe sizes.
        switch self {
        case .pride: "B99CFF"
        case .anger: "FF776D"
        case .envy: "63D8A1"
        case .gluttony: "FFB765"
        case .lust: "FF83B4"
        case .greed: "E4C75A"
        case .sloth: "79B8FF"
        }
    }

    var color: Color { Color(hex: hex) }
}

struct DayRecord: Codable, Identifiable, Hashable {
    var day: Date
    var fallDates: [Date] = []
    var morningResolved = false
    var middayCompleted = false
    var eveningCompleted = false
    var morningFalls: Int?
    var afternoonFalls: Int?

    var id: Date { Calendar.current.startOfDay(for: day) }
    var totalFalls: Int { fallDates.count }
    var isComplete: Bool { morningResolved && middayCompleted && eveningCompleted }
}

struct NotificationSchedule: Codable, Hashable {
    var morningEnabled = false
    var morningHour = 7
    var morningMinute = 0
    var middayEnabled = false
    var middayHour = 13
    var middayMinute = 0
    var eveningEnabled = false
    var eveningHour = 20
    var eveningMinute = 0
}

struct ExamenData: Codable {
    var selectedVice: Vice?
    var selectedAt: Date?
    var commitmentDays = 90
    var overrideUnlocked = false
    var records: [DayRecord] = []
    var notifications = NotificationSchedule()

    init(
        selectedVice: Vice? = nil,
        selectedAt: Date? = nil,
        commitmentDays: Int = 90,
        overrideUnlocked: Bool = false,
        records: [DayRecord] = [],
        notifications: NotificationSchedule = NotificationSchedule()
    ) {
        self.selectedVice = selectedVice
        self.selectedAt = selectedAt
        self.commitmentDays = Self.validCommitmentDays(commitmentDays)
        self.overrideUnlocked = overrideUnlocked
        self.records = records
        self.notifications = notifications
    }

    private enum CodingKeys: String, CodingKey {
        case selectedVice, selectedAt, commitmentDays, overrideUnlocked, records, notifications
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        selectedVice = try container.decodeIfPresent(Vice.self, forKey: .selectedVice)
        selectedAt = try container.decodeIfPresent(Date.self, forKey: .selectedAt)
        commitmentDays = Self.validCommitmentDays(
            try container.decodeIfPresent(Int.self, forKey: .commitmentDays) ?? 90
        )
        overrideUnlocked = try container.decodeIfPresent(Bool.self, forKey: .overrideUnlocked) ?? false
        records = try container.decodeIfPresent([DayRecord].self, forKey: .records) ?? []
        notifications = try container.decodeIfPresent(NotificationSchedule.self, forKey: .notifications) ?? NotificationSchedule()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(selectedVice, forKey: .selectedVice)
        try container.encodeIfPresent(selectedAt, forKey: .selectedAt)
        try container.encode(commitmentDays, forKey: .commitmentDays)
        try container.encode(overrideUnlocked, forKey: .overrideUnlocked)
        try container.encode(records, forKey: .records)
        try container.encode(notifications, forKey: .notifications)
    }

    private static func validCommitmentDays(_ days: Int) -> Int {
        [30, 60, 90].contains(days) ? days : 90
    }

    var commitmentEndDate: Date? {
        guard let selectedAt else { return nil }
        return Calendar.current.date(byAdding: .day, value: commitmentDays, to: selectedAt)
    }

    var mayChooseVice: Bool {
        guard selectedVice != nil, let commitmentEndDate else { return true }
        return overrideUnlocked || Date() >= commitmentEndDate
    }

    func record(for date: Date) -> DayRecord? {
        let target = Calendar.current.startOfDay(for: date)
        return records.first { Calendar.current.isDate($0.day, inSameDayAs: target) }
    }

    var totalCompletedDays: Int { records.filter(\.isComplete).count }

    func averageFalls(overLast numberOfDays: Int, endingAt date: Date = Date()) -> Double {
        guard numberOfDays > 0 else { return 0 }
        let calendar = Calendar.current
        let end = calendar.startOfDay(for: date)
        let requestedStart = calendar.date(byAdding: .day, value: -(numberOfDays - 1), to: end) ?? end
        let campaignStart = selectedAt.map { calendar.startOfDay(for: $0) } ?? requestedStart
        let start = max(requestedStart, campaignStart)
        guard start <= end else { return 0 }

        let completedRecords = records.filter { record in
            let day = calendar.startOfDay(for: record.day)
            return day >= start && day <= end && record.isComplete
        }
        guard !completedRecords.isEmpty else { return 0 }
        let total = completedRecords.reduce(0) { $0 + $1.totalFalls }
        return Double(total) / Double(completedRecords.count)
    }

    func recentDailyFalls(numberOfDays: Int, endingAt date: Date = Date()) -> [(date: Date, falls: Int)] {
        let calendar = Calendar.current
        let end = calendar.startOfDay(for: date)
        return (0..<max(0, numberOfDays)).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: end) else { return nil }
            return (day, record(for: day)?.totalFalls ?? 0)
        }
    }

    var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayRecord = record(for: today)
        var cursor = (todayRecord?.isComplete == true)
            ? today
            : calendar.date(byAdding: .day, value: -1, to: today)!
        var streak = 0

        while record(for: cursor)?.isComplete == true {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }
}

extension Color {
    init(hex: String) {
        let value = UInt64(hex, radix: 16) ?? 0
        self.init(
            .sRGB,
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255,
            opacity: 1
        )
    }
}

enum ExamenPalette {
    static let background = Color(hex: "101114")
    static let surface = Color(hex: "1A1C20")
    static let raised = Color(hex: "23262B")
    static let text = Color(hex: "F5F1E8")
    static let secondaryText = Color(hex: "C4C7CC")
    static let quietText = Color(hex: "9DA2AA")
    static let defaultAccent = Color(hex: "8FC5FF")
}
