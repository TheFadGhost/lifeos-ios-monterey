import XCTest
@testable import LifeOS

final class LifeOSLogicTests: XCTestCase {
    func testCompletionPercentClampsCompletedValues() {
        XCTAssertEqual(LifeMetrics.completionPercent(completed: 0, total: 0), 0)
        XCTAssertEqual(LifeMetrics.completionPercent(completed: 2, total: 4), 0.5)
        XCTAssertEqual(LifeMetrics.completionPercent(completed: 7, total: 4), 1)
        XCTAssertEqual(LifeMetrics.completionPercent(completed: -1, total: 4), 0)
    }

    func testGreetingMatchesAndroidTimeWindows() {
        XCTAssertEqual(LifeMetrics.greeting(forHour: 5), "Good morning")
        XCTAssertEqual(LifeMetrics.greeting(forHour: 11), "Good afternoon")
        XCTAssertEqual(LifeMetrics.greeting(forHour: 17), "Good evening")
        XCTAssertEqual(LifeMetrics.greeting(forHour: 22), "Time to wind down")
    }

    func testHabitStreakCountsBackFromToday() throws {
        let today = try XCTUnwrap(DateFormatter.lifeOSDay.date(from: "2026-07-02"))
        let dates = [
            "2026-07-02",
            "2026-07-01",
            "2026-06-30",
            "2026-06-28"
        ].compactMap(DateFormatter.lifeOSDay.date(from:))

        XCTAssertEqual(LifeMetrics.habitStreak(for: dates, today: today), 3)
    }

    func testQuickCaptureDailyTaskExpandsSevenOccurrences() throws {
        let today = try XCTUnwrap(DateFormatter.lifeOSDay.date(from: "2026-07-02"))
        let plan = try XCTUnwrap(QuickCaptureParser.parse("task revise maths daily tomorrow", today: today))

        XCTAssertEqual(plan.action, .task)
        XCTAssertEqual(plan.title, "revise maths")
        XCTAssertEqual(plan.recurrence, .daily)
        XCTAssertEqual(plan.occurrenceDates.map(\.lifeOSDayString), [
            "2026-07-03",
            "2026-07-04",
            "2026-07-05",
            "2026-07-06",
            "2026-07-07",
            "2026-07-08",
            "2026-07-09"
        ])
    }

    func testQuickCaptureDefaultsToTaskAndParsesIsoDate() throws {
        let today = try XCTUnwrap(DateFormatter.lifeOSDay.date(from: "2026-07-02"))
        let plan = try XCTUnwrap(QuickCaptureParser.parse("pay rent 2026-07-10", today: today))

        XCTAssertEqual(plan.action, .task)
        XCTAssertEqual(plan.title, "pay rent")
        XCTAssertEqual(plan.date.lifeOSDayString, "2026-07-10")
    }

    func testCommandSearchRanksTitleMatchesFirst() {
        let items = [
            CommandSearchItem(title: "Smart daily plan", subtitle: "Today across modules", route: .dashboard, type: .action, keywords: ["today"]),
            CommandSearchItem(title: "Privacy controls", subtitle: "Hide plan preview", route: .settings, type: .setting, keywords: ["private"]),
            CommandSearchItem(title: "Task Inbox", subtitle: "Plan a study day", route: .tasks, type: .task)
        ]

        let results = CommandSearch.filter(items: items, query: "plan")

        XCTAssertEqual(results.map(\.title), ["Smart daily plan", "Privacy controls", "Task Inbox"])
    }

    func testSmartPlanIncludesOverdueTasksOpenHabitsAndWorkoutPrompt() throws {
        let today = try XCTUnwrap(DateFormatter.lifeOSDay.date(from: "2026-07-02"))
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let habit = Habit(title: "Read", sortOrder: 0)
        let task = LifeTask(title: "Submit essay", dueDate: yesterday, priority: .high)

        let plan = SmartDailyPlan.build(
            today: today,
            tasks: [task],
            habits: [habit],
            habitLogsToday: [],
            events: [],
            reminders: [],
            workoutsToday: 0,
            readingItems: []
        )

        XCTAssertTrue(plan.contains { $0.title == "Submit essay" && $0.urgency == .overdue })
        XCTAssertTrue(plan.contains { $0.title == "Read" && $0.urgency == .today })
        XCTAssertTrue(plan.contains { $0.title == "Log a workout" && $0.urgency == .optional })
    }

    func testFocusSessionFormattingAndProgress() {
        XCTAssertEqual(FocusSessionLogic.formatRemaining(totalSeconds: 65), "01:05")
        XCTAssertEqual(FocusSessionLogic.formatRemaining(totalSeconds: -5), "00:00")
        XCTAssertEqual(FocusSessionLogic.progress(totalSeconds: 100, remainingSeconds: 25), 0.75)
        XCTAssertEqual(FocusSessionLogic.progress(totalSeconds: 0, remainingSeconds: 0), 0)
    }
}
