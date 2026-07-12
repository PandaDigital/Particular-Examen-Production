import AppIntents
import WidgetKit

struct RecordFallIntent: AppIntent {
    static let title: LocalizedStringResource = "Record a fall"
    static let description = IntentDescription("Adds one fall to today’s Particular Examen.")
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        ExamenRepository.addFall()
        return .result()
    }
}
