import Foundation

enum LifeOSExport {
    static func export(state: LifeOSState, now: Date = Date()) throws -> URL {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"

        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("LifeOS Export \(formatter.string(from: now))", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true, attributes: nil)

        let stateData = try JSONEncoder.lifeOS.encode(state)
        try stateData.write(to: root.appendingPathComponent("state.json"), options: [.atomic])

        let manifest = ExportManifest(schemaVersion: 1, appVersion: "1.00", exportedAt: now, platform: "iOS")
        let manifestData = try JSONEncoder.lifeOS.encode(manifest)
        try manifestData.write(to: root.appendingPathComponent("manifest.json"), options: [.atomic])

        try writeCSV(rows: state.habits.map { [$0.id.uuidString, $0.title, $0.description, "\($0.isActive)", "\($0.sortOrder)"] }, headers: ["id", "title", "description", "isActive", "sortOrder"], to: root.appendingPathComponent("habits.csv"))
        try writeCSV(rows: state.tasks.map { [$0.id.uuidString, $0.title, $0.notes, $0.dueDate?.lifeOSDayString ?? "", $0.priority.rawValue, $0.status.rawValue] }, headers: ["id", "title", "notes", "dueDate", "priority", "status"], to: root.appendingPathComponent("tasks.csv"))
        try writeCSV(rows: state.events.map { [$0.id.uuidString, $0.title, $0.notes, $0.date.lifeOSDayString, $0.category] }, headers: ["id", "title", "notes", "date", "category"], to: root.appendingPathComponent("events.csv"))
        try writeCSV(rows: state.expenses.map { [$0.id.uuidString, "\($0.amountMinor)", $0.currency, $0.categoryID?.uuidString ?? "", $0.date.lifeOSDayString, $0.notes] }, headers: ["id", "amountMinor", "currency", "categoryId", "date", "notes"], to: root.appendingPathComponent("expenses.csv"))
        try writeCSV(rows: state.journalEntries.map { [$0.id.uuidString, $0.date.lifeOSDayString, $0.prompt, $0.body, $0.moodRating.map(String.init) ?? "", $0.moodEmoji ?? ""] }, headers: ["id", "date", "prompt", "body", "moodRating", "moodEmoji"], to: root.appendingPathComponent("journal_entries.csv"))
        try writeCSV(rows: state.readingItems.map { [$0.id.uuidString, $0.title, $0.type.rawValue, $0.status.rawValue, $0.sourceLabel, $0.notes] }, headers: ["id", "title", "type", "status", "sourceLabel", "notes"], to: root.appendingPathComponent("reading_items.csv"))
        try writeCSV(rows: state.notes.map { [$0.id.uuidString, $0.title, $0.body, "\($0.isPinned)", "\($0.wordCount)", $0.deletedAt?.lifeOSDayString ?? ""] }, headers: ["id", "title", "body", "isPinned", "wordCount", "deletedAt"], to: root.appendingPathComponent("notes.csv"))

        let settingsData = try JSONEncoder.lifeOS.encode(state.settings)
        try settingsData.write(to: root.appendingPathComponent("layout_settings.json"), options: [.atomic])

        return root
    }

    private static func writeCSV(rows: [[String]], headers: [String], to url: URL) throws {
        let lines = [headers] + rows
        let text = lines.map { row in
            row.map(escapeCSV).joined(separator: ",")
        }.joined(separator: "\n")
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    private static func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}

private struct ExportManifest: Codable {
    var schemaVersion: Int
    var appVersion: String
    var exportedAt: Date
    var platform: String
}
