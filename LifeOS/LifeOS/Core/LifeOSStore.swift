import Combine
import Foundation

@MainActor
final class LifeOSStore: ObservableObject {
    @Published private(set) var state: LifeOSState
    @Published var lastError: String?
    @Published var lastExportURL: URL?

    private let fileURL: URL
    private let scheduler: ReminderScheduling
    private let calendar: Calendar

    init(
        fileURL: URL? = nil,
        scheduler: ReminderScheduling = LocalReminderScheduler.shared,
        calendar: Calendar = .current
    ) {
        self.fileURL = fileURL ?? Self.defaultStoreURL()
        self.scheduler = scheduler
        self.calendar = calendar
        self.state = Self.load(from: self.fileURL) ?? LifeOSState.seeded(calendar: calendar)
        persist()
    }

    var visibleBottomRoutes: [LifeRoute] {
        let savedOrder = state.settings.navOrder.filter { LifeRoute.bottomRoutes.contains($0) }
        let missing = LifeRoute.bottomRoutes.filter { !savedOrder.contains($0) }
        return (savedOrder + missing).filter { route in
            route == .dashboard || !state.settings.hiddenRoutes.contains(route)
        }
    }

    func requestNotificationPermission() {
        Task {
            _ = await scheduler.requestAuthorization()
        }
    }

    func resetDemoData() {
        state = LifeOSState.seeded(calendar: calendar)
        persist()
    }

    func setTheme(_ theme: ThemePreference) {
        state.settings.theme = theme
        persist()
    }

    func setPrivacyMode(_ enabled: Bool) {
        state.settings.privacyMode = enabled
        persist()
    }

    func setHideWidgetDetails(_ enabled: Bool) {
        state.settings.hideWidgetDetails = enabled
        persist()
    }

    func setWidgetEnabled(_ enabled: Bool) {
        state.settings.widgetEnabled = enabled
        persist()
    }

    func setConfirmBeforeExport(_ enabled: Bool) {
        state.settings.confirmBeforeExport = enabled
        persist()
    }

    func setRoute(_ route: LifeRoute, hidden: Bool) {
        guard route != .dashboard else { return }
        if hidden {
            state.settings.hiddenRoutes.insert(route)
        } else {
            state.settings.hiddenRoutes.remove(route)
        }
        persist()
    }

    func moveRoute(_ route: LifeRoute, direction: Int) {
        var order = state.settings.navOrder.filter { LifeRoute.bottomRoutes.contains($0) }
        for missing in LifeRoute.bottomRoutes where !order.contains(missing) {
            order.append(missing)
        }
        guard let index = order.firstIndex(of: route) else { return }
        let target = min(max(index + direction, 0), order.count - 1)
        guard target != index else { return }
        order.swapAt(index, target)
        state.settings.navOrder = order
        persist()
    }

    func addHabit(title: String, description: String = "") {
        guard let title = title.trimmedNonEmpty else { return }
        let sortOrder = (state.habits.map(\.sortOrder).max() ?? -1) + 1
        state.habits.append(Habit(title: title, description: description, sortOrder: sortOrder))
        persist()
    }

    func updateHabit(_ habit: Habit, title: String, description: String) {
        guard let title = title.trimmedNonEmpty, let index = state.habits.firstIndex(where: { $0.id == habit.id }) else { return }
        state.habits[index].title = title
        state.habits[index].description = description
        persist()
    }

    func deleteHabit(_ habitID: UUID) {
        if let index = state.habits.firstIndex(where: { $0.id == habitID }) {
            state.habits[index].isActive = false
            state.habitLogs.removeAll { $0.habitID == habitID }
            removeReminders(sourceID: habitID)
            persist()
        }
    }

    func toggleHabit(_ habitID: UUID, date: Date = Date()) {
        let day = calendar.startOfDay(for: date)
        if let index = state.habitLogs.firstIndex(where: { $0.habitID == habitID && calendar.isDate($0.date, inSameDayAs: day) }) {
            state.habitLogs.remove(at: index)
        } else {
            state.habitLogs.append(HabitLog(habitID: habitID, date: day))
        }
        persist()
    }

    func addTask(
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        priority: TaskPriority = .medium,
        status: TaskStatus = .notStarted,
        folderID: UUID? = nil,
        tagIDs: [UUID] = []
    ) {
        guard let title = title.trimmedNonEmpty else { return }
        state.tasks.append(
            LifeTask(
                folderID: folderID,
                title: title,
                notes: notes,
                dueDate: dueDate.map { calendar.startOfDay(for: $0) },
                priority: priority,
                status: status,
                tagIDs: tagIDs
            )
        )
        persist()
    }

    func updateTaskStatus(_ taskID: UUID, status: TaskStatus) {
        guard let index = state.tasks.firstIndex(where: { $0.id == taskID }) else { return }
        state.tasks[index].status = status
        state.tasks[index].updatedAt = Date()
        state.tasks[index].completedAt = status == .done ? Date() : nil
        persist()
    }

    func deleteTask(_ taskID: UUID) {
        state.tasks.removeAll { $0.id == taskID }
        removeReminders(sourceID: taskID)
        persist()
    }

    func addTag(name: String, color: String = "#2F80ED") {
        guard let name = name.trimmedNonEmpty else { return }
        if !state.tags.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            state.tags.append(Tag(name: name, color: color))
            persist()
        }
    }

    func addEvent(title: String, notes: String = "", date: Date, category: String = "General") {
        guard let title = title.trimmedNonEmpty else { return }
        state.events.append(CalendarEvent(title: title, notes: notes, date: calendar.startOfDay(for: date), category: category))
        persist()
    }

    func deleteEvent(_ eventID: UUID) {
        state.events.removeAll { $0.id == eventID }
        removeReminders(sourceID: eventID)
        persist()
    }

    func addExpense(amountMinor: Int, categoryID: UUID?, date: Date, notes: String) {
        guard amountMinor > 0 else { return }
        state.expenses.append(
            Expense(
                amountMinor: amountMinor,
                currency: state.settings.currency,
                categoryID: categoryID,
                date: calendar.startOfDay(for: date),
                notes: notes
            )
        )
        persist()
    }

    func deleteExpense(_ expenseID: UUID) {
        state.expenses.removeAll { $0.id == expenseID }
        removeReminders(sourceID: expenseID)
        persist()
    }

    func logWorkoutSet(exerciseID: UUID, reps: Int, weight: Double, date: Date = Date()) {
        guard reps > 0, weight >= 0 else { return }
        let day = calendar.startOfDay(for: date)
        let sessionID: UUID
        if let existing = state.workoutSessions.first(where: { calendar.isDate($0.date, inSameDayAs: day) }) {
            sessionID = existing.id
        } else {
            let session = WorkoutSession(date: day)
            state.workoutSessions.append(session)
            sessionID = session.id
        }
        let setNumber = state.workoutSets.filter { $0.sessionID == sessionID && $0.exerciseID == exerciseID }.count + 1
        state.workoutSets.append(WorkoutSet(sessionID: sessionID, exerciseID: exerciseID, setNumber: setNumber, reps: reps, weight: weight))
        persist()
    }

    func deleteWorkoutSet(_ setID: UUID) {
        state.workoutSets.removeAll { $0.id == setID }
        let usedSessions = Set(state.workoutSets.map(\.sessionID))
        state.workoutSessions.removeAll { !usedSessions.contains($0.id) }
        persist()
    }

    func saveJournal(date: Date, body: String, moodRating: Int?, moodEmoji: String?) {
        let day = calendar.startOfDay(for: date)
        let rating = moodRating.map { min(max($0, 1), 5) }
        if let index = state.journalEntries.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: day) }) {
            state.journalEntries[index].body = body
            state.journalEntries[index].moodRating = rating
            state.journalEntries[index].moodEmoji = moodEmoji
            state.journalEntries[index].updatedAt = Date()
        } else {
            state.journalEntries.append(JournalEntry(date: day, body: body, moodRating: rating, moodEmoji: moodEmoji))
        }
        persist()
    }

    func addReadingItem(title: String, type: ReadingType = .other, sourceLabel: String = "", notes: String = "") {
        guard let title = title.trimmedNonEmpty else { return }
        state.readingItems.append(ReadingItem(title: title, type: type, notes: notes, sourceLabel: sourceLabel))
        persist()
    }

    func updateReadingStatus(_ itemID: UUID, status: ReadingStatus) {
        guard let index = state.readingItems.firstIndex(where: { $0.id == itemID }) else { return }
        state.readingItems[index].status = status
        state.readingItems[index].completedAt = status == .completed ? Date() : nil
        persist()
    }

    func deleteReadingItem(_ itemID: UUID) {
        state.readingItems.removeAll { $0.id == itemID }
        removeReminders(sourceID: itemID)
        persist()
    }

    func addNote(title: String, body: String = "", folderID: UUID? = nil, isDaily: Bool = false, dailyDate: Date? = nil) {
        let now = Date()
        let noteTitle = title.trimmedNonEmpty ?? "Untitled note"
        let cleanBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        state.notes.append(
            LifeNote(
                folderID: folderID,
                title: noteTitle,
                body: cleanBody,
                isDaily: isDaily,
                dailyDate: dailyDate.map { calendar.startOfDay(for: $0) },
                wordCount: cleanBody.lifeOSWordCount,
                createdAt: now,
                updatedAt: now
            )
        )
        persist()
    }

    func updateNote(_ noteID: UUID, title: String, body: String, isPinned: Bool) {
        guard let index = state.notes.firstIndex(where: { $0.id == noteID }) else { return }
        state.notes[index].title = title.trimmedNonEmpty ?? "Untitled note"
        state.notes[index].body = body
        state.notes[index].isPinned = isPinned
        state.notes[index].wordCount = body.lifeOSWordCount
        state.notes[index].updatedAt = Date()
        persist()
    }

    func deleteNote(_ noteID: UUID) {
        guard let index = state.notes.firstIndex(where: { $0.id == noteID }) else { return }
        state.notes[index].deletedAt = Date()
        persist()
    }

    @discardableResult
    func quickCapture(_ input: String, today: Date = Date()) -> QuickCaptureResult {
        guard let plan = QuickCaptureParser.parse(input, today: today, calendar: calendar) else {
            return QuickCaptureResult(success: false, message: "Type a task, event, habit, note, reading item, or focus idea.")
        }

        let count = plan.occurrenceDates.count
        switch plan.action {
        case .task:
            for date in plan.occurrenceDates {
                addTask(title: plan.title, notes: plan.notes, dueDate: date)
            }
            return QuickCaptureResult(success: true, message: "Added \(count) \(plural("task", count)).")
        case .event:
            for date in plan.occurrenceDates {
                addEvent(title: plan.title, notes: plan.notes, date: date, category: plan.recurrence == .none ? "Quick capture" : "Recurring")
            }
            return QuickCaptureResult(success: true, message: "Added \(count) \(plural("event", count)).")
        case .journal:
            saveJournal(date: plan.date, body: plan.title, moodRating: nil, moodEmoji: nil)
            return QuickCaptureResult(success: true, message: "Saved today's journal note.")
        case .reading:
            addReadingItem(title: plan.title, type: .other, sourceLabel: "Quick capture")
            return QuickCaptureResult(success: true, message: "Added reading item.")
        case .habit:
            addHabit(title: plan.title)
            return QuickCaptureResult(success: true, message: "Added habit.")
        case .focus:
            return QuickCaptureResult(success: true, message: "Focus idea ready: \(plan.title)")
        }
    }

    func addReminder(sourceType: ReminderSourceType, sourceID: UUID, title: String, message: String, scheduledAt: Date) {
        guard scheduledAt > Date(), let title = title.trimmedNonEmpty else { return }
        let reminder = Reminder(sourceType: sourceType, sourceID: sourceID, title: title, message: message, scheduledAt: scheduledAt)
        state.reminders.removeAll { $0.sourceType == sourceType && $0.sourceID == sourceID }
        state.reminders.append(reminder)
        scheduler.schedule(reminder)
        persist()
    }

    func cancelReminder(_ reminderID: UUID) {
        state.reminders.removeAll { $0.id == reminderID }
        scheduler.cancel(reminderID: reminderID)
        persist()
    }

    func exportLocalArchive() {
        do {
            lastExportURL = try LifeOSExport.export(state: state)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func removeReminders(sourceID: UUID) {
        let removed = state.reminders.filter { $0.sourceID == sourceID }
        state.reminders.removeAll { $0.sourceID == sourceID }
        for reminder in removed {
            scheduler.cancel(reminderID: reminder.id)
        }
    }

    private func persist() {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            let encoder = JSONEncoder.lifeOS
            let data = try encoder.encode(state)
            try data.write(to: fileURL, options: [.atomic])
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    private static func load(from url: URL) -> LifeOSState? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder.lifeOS.decode(LifeOSState.self, from: data)
    }

    private static func defaultStoreURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("LifeOS", isDirectory: true).appendingPathComponent("lifeos-store-v1.json")
    }
}

extension JSONEncoder {
    static var lifeOS: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var lifeOS: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

private func plural(_ word: String, _ count: Int) -> String {
    count == 1 ? word : "\(word)s"
}

private extension String {
    var lifeOSWordCount: Int {
        split { $0.isWhitespace || $0.isNewline }.count
    }
}
