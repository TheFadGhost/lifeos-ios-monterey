import XCTest
@testable import LifeOS

final class LifeOSStoreTests: XCTestCase {
    func testSeededStateMatchesAndroidDefaults() {
        let state = LifeOSState.seeded()

        XCTAssertEqual(state.settings.currency, "GBP")
        XCTAssertEqual(state.habits.map(\.title), ["Drink water", "Read", "Meditate", "Exercise"])
        XCTAssertEqual(state.taskFolders.map(\.name), ["Work", "Personal", "Studies"])
        XCTAssertEqual(state.expenseCategories.map(\.name), ["Rent", "Food", "Transport", "Health", "Fitness", "Subscriptions", "Other"])
        XCTAssertTrue(state.exercises.contains { $0.name == "Push-up" })
    }

    @MainActor
    func testHabitToggleAddsAndRemovesTodayLog() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("json")
        let store = LifeOSStore(fileURL: url, scheduler: InMemoryReminderScheduler())
        let habit = try XCTUnwrap(store.state.habits.first)
        let today = try XCTUnwrap(DateFormatter.lifeOSDay.date(from: "2026-07-02"))

        store.toggleHabit(habit.id, date: today)
        XCTAssertEqual(store.state.habitLogs.filter { $0.habitID == habit.id }.count, 1)

        store.toggleHabit(habit.id, date: today)
        XCTAssertEqual(store.state.habitLogs.filter { $0.habitID == habit.id }.count, 0)
    }

    @MainActor
    func testStoreQuickCaptureAddsRecurringTasks() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("json")
        let store = LifeOSStore(fileURL: url, scheduler: InMemoryReminderScheduler())
        let today = try XCTUnwrap(DateFormatter.lifeOSDay.date(from: "2026-07-02"))

        let result = store.quickCapture("task revise maths daily tomorrow", today: today)

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.message, "Added 7 tasks.")
        XCTAssertEqual(store.state.tasks.filter { $0.title == "revise maths" }.count, 7)
    }

    @MainActor
    func testStorePersistsJsonRoundTrip() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("json")
        let firstStore = LifeOSStore(fileURL: url, scheduler: InMemoryReminderScheduler())
        firstStore.addHabit(title: "Sleep early")

        let secondStore = LifeOSStore(fileURL: url, scheduler: InMemoryReminderScheduler())

        XCTAssertTrue(secondStore.state.habits.contains { $0.title == "Sleep early" })
    }
}

private final class InMemoryReminderScheduler: ReminderScheduling {
    var scheduled: [Reminder] = []
    var cancelled: [UUID] = []

    func requestAuthorization() async -> Bool { true }

    func schedule(_ reminder: Reminder) {
        scheduled.append(reminder)
    }

    func cancel(reminderID: UUID) {
        cancelled.append(reminderID)
    }
}
