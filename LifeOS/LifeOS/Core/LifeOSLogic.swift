import Foundation

enum LifeMetrics {
    static func completionPercent(completed: Int, total: Int) -> Double {
        guard total > 0 else { return 0 }
        let clamped = min(max(completed, 0), total)
        return min(max(Double(clamped) / Double(total), 0), 1)
    }

    static func greeting(forHour hour: Int) -> String {
        let safeHour = min(max(hour, 0), 23)
        switch safeHour {
        case 5...10: return "Good morning"
        case 11...16: return "Good afternoon"
        case 17...20: return "Good evening"
        default: return "Time to wind down"
        }
    }

    static func habitStreak(for completedDates: [Date], today: Date = Date(), calendar: Calendar = .current) -> Int {
        let completed = Set(completedDates.map { calendar.startOfDay(for: $0).lifeOSDayString })
        var cursor = calendar.startOfDay(for: today)
        var streak = 0
        while completed.contains(cursor.lifeOSDayString) {
            streak += 1
            cursor = cursor.addingDays(-1, calendar: calendar)
        }
        return streak
    }
}

enum SearchFilters {
    static func matchesTask(_ task: LifeTask, query: String) -> Bool {
        matchesText([
            task.title,
            task.notes,
            task.dueDate?.lifeOSDayString ?? "",
            task.priority.rawValue,
            task.status.label
        ], query: query)
    }

    static func matchesReading(_ item: ReadingItem, query: String) -> Bool {
        matchesText([
            item.title,
            item.notes,
            item.type.rawValue,
            item.status.label,
            item.sourceLabel
        ], query: query)
    }

    static func matchesJournal(_ entry: JournalEntry, query: String) -> Bool {
        matchesText([
            entry.date.lifeOSDayString,
            entry.prompt,
            entry.body,
            entry.moodRating.map(String.init) ?? "",
            entry.moodEmoji ?? ""
        ], query: query)
    }

    static func matchesText(_ values: [String], query: String) -> Bool {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return true }
        return values.contains { $0.lowercased().contains(normalized) }
    }
}

enum CommandResultType: String, Codable {
    case action
    case task
    case habit
    case event
    case expense
    case workout
    case journal
    case reading
    case setting
    case note
}

struct CommandSearchItem: Identifiable, Equatable {
    var id: String { "\(route.rawValue)-\(type.rawValue)-\(title)-\(subtitle)" }
    var title: String
    var subtitle: String
    var route: LifeRoute
    var type: CommandResultType
    var keywords: [String] = []
}

enum CommandSearch {
    static func filter(items: [CommandSearchItem], query: String, limit: Int = 8) -> [CommandSearchItem] {
        let terms = query.normalizedSearchText.split(separator: " ").map(String.init).filter { !$0.isEmpty }
        guard !terms.isEmpty else { return [] }

        var scoredItems: [CommandSearchScore] = []
        for (index, item) in items.enumerated() {
            let score = score(item: item, terms: terms)
            if score > 0 {
                scoredItems.append(CommandSearchScore(index: index, score: score, item: item))
            }
        }

        scoredItems.sort { left, right in
            if left.score == right.score {
                return left.index < right.index
            }
            return left.score > right.score
        }

        let resultLimit = max(limit, 1)
        var results: [CommandSearchItem] = []
        for scoredItem in scoredItems {
            if results.count >= resultLimit {
                break
            }
            results.append(scoredItem.item)
        }
        return results
    }

    private static func score(item: CommandSearchItem, terms: [String]) -> Int {
        let title = item.title.normalizedSearchText
        let subtitle = item.subtitle.normalizedSearchText
        let keywords = item.keywords.joined(separator: " ").normalizedSearchText
        let route = item.route.rawValue.normalizedSearchText

        var score = 0
        for term in terms {
            if title.contains(term) {
                score += 6
            } else if keywords.contains(term) {
                score += 5
            } else if subtitle.contains(term) {
                score += 3
            } else if route.contains(term) {
                score += 1
            }
        }
        return score
    }
}

private struct CommandSearchScore {
    var index: Int
    var score: Int
    var item: CommandSearchItem
}

enum PlanUrgency: Int, Codable {
    case overdue
    case today
    case upcoming
    case optional

    var label: String {
        switch self {
        case .overdue: return "Overdue"
        case .today: return "Today"
        case .upcoming: return "Upcoming"
        case .optional: return "Optional"
        }
    }
}

struct SmartPlanItem: Identifiable, Equatable {
    var id: String { "\(route.rawValue)-\(urgency.rawValue)-\(title)-\(subtitle)" }
    var title: String
    var subtitle: String
    var route: LifeRoute
    var urgency: PlanUrgency
}

enum SmartDailyPlan {
    static func build(
        today: Date,
        tasks: [LifeTask],
        habits: [Habit],
        habitLogsToday: [HabitLog],
        events: [CalendarEvent],
        reminders: [Reminder],
        workoutsToday: Int,
        readingItems: [ReadingItem],
        calendar: Calendar = .current
    ) -> [SmartPlanItem] {
        let day = calendar.startOfDay(for: today)
        let completedHabitIDs = Set(habitLogsToday.map(\.habitID))
        let openTasks = tasks
            .filter { task in
                guard let dueDate = task.dueDate else { return false }
                return task.status != .done && calendar.startOfDay(for: dueDate) <= day
            }
            .sorted {
                let left = $0.dueDate ?? day
                let right = $1.dueDate ?? day
                if left == right { return $0.priority.sortRank > $1.priority.sortRank }
                return left < right
            }
            .map { task in
                let overdue = (task.dueDate ?? day) < day
                return SmartPlanItem(
                    title: task.title,
                    subtitle: overdue ? "Overdue task" : "Due today",
                    route: .tasks,
                    urgency: overdue ? .overdue : .today
                )
            }

        let habitItems = habits
            .filter { $0.isActive && !completedHabitIDs.contains($0.id) }
            .map {
                SmartPlanItem(title: $0.title, subtitle: "Habit still open today", route: .habits, urgency: .today)
            }

        let eventItems = events
            .filter { calendar.startOfDay(for: $0.date) >= day }
            .sorted { ($0.startTimeMinutes ?? 0) < ($1.startTimeMinutes ?? 0) }
            .map { event in
                let todayEvent = calendar.isDate(event.date, inSameDayAs: day)
                return SmartPlanItem(
                    title: event.title,
                    subtitle: todayEvent ? "Today's event" : "Upcoming event",
                    route: .calendar,
                    urgency: todayEvent ? .today : .upcoming
                )
            }

        let reminderItems = reminders.filter(\.enabled).map {
            SmartPlanItem(
                title: $0.title,
                subtitle: $0.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Reminder" : $0.message,
                route: .dashboard,
                urgency: .upcoming
            )
        }

        let workoutItem = workoutsToday <= 0
            ? [SmartPlanItem(title: "Log a workout", subtitle: "No workout logged today", route: .fitness, urgency: .optional)]
            : []

        let readingItemsToday = readingItems
            .filter { $0.status != .completed && $0.status != .archived }
            .prefix(2)
            .map {
                SmartPlanItem(title: $0.title, subtitle: "Reading goal", route: .journal, urgency: .optional)
            }

        return (openTasks + habitItems + eventItems + reminderItems + workoutItem + readingItemsToday)
            .sorted {
                if $0.urgency.rawValue == $1.urgency.rawValue {
                    return $0.title.lowercased() < $1.title.lowercased()
                }
                return $0.urgency.rawValue < $1.urgency.rawValue
            }
            .prefix(12)
            .map { $0 }
    }
}

enum QuickCaptureAction: Codable {
    case task
    case event
    case journal
    case reading
    case habit
    case focus
}

enum RecurrenceRule: Codable {
    case none
    case daily
    case weekly
    case monthly
}

struct QuickCapturePlan: Equatable {
    var action: QuickCaptureAction
    var title: String
    var notes: String = ""
    var date: Date
    var recurrence: RecurrenceRule = .none
    var occurrenceDates: [Date]
}

enum QuickCaptureParser {
    static func parse(_ input: String, today: Date = Date(), calendar: Calendar = .current) -> QuickCapturePlan? {
        let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }

        var tokens = cleaned.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return nil }

        let maybeAction = action(for: tokens[0])
        let action = maybeAction ?? .task
        if maybeAction != nil {
            tokens.removeFirst()
        }

        let recurrenceRule = tokens.compactMap(Self.recurrence(for:)).first ?? .none
        tokens.removeAll { Self.recurrence(for: $0) != nil }

        let dateToken = tokens.first { friendlyDate(for: $0, today: today, calendar: calendar) != nil }
        let date = dateToken.flatMap { friendlyDate(for: $0, today: today, calendar: calendar) } ?? calendar.startOfDay(for: today)
        if let dateToken {
            tokens.removeAll { $0 == dateToken }
        }

        let title = tokens.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }

        return QuickCapturePlan(
            action: action,
            title: title,
            date: date,
            recurrence: recurrenceRule,
            occurrenceDates: occurrenceDates(firstDate: date, recurrence: recurrenceRule, calendar: calendar)
        )
    }

    private static func action(for token: String) -> QuickCaptureAction? {
        switch token.lowercased() {
        case "task", "todo": return .task
        case "event", "calendar": return .event
        case "journal", "note", "reflect": return .journal
        case "read", "reading", "book", "article": return .reading
        case "habit": return .habit
        case "focus", "timer": return .focus
        default: return nil
        }
    }

    private static func recurrence(for token: String) -> RecurrenceRule? {
        switch token.lowercased() {
        case "daily", "everyday": return .daily
        case "weekly": return .weekly
        case "monthly": return .monthly
        default: return nil
        }
    }

    private static func friendlyDate(for token: String, today: Date, calendar: Calendar) -> Date? {
        switch token.lowercased() {
        case "today":
            return calendar.startOfDay(for: today)
        case "tomorrow":
            return calendar.startOfDay(for: today).addingDays(1, calendar: calendar)
        default:
            return DateFormatter.lifeOSDay.date(from: token)
        }
    }

    private static func occurrenceDates(firstDate: Date, recurrence: RecurrenceRule, calendar: Calendar) -> [Date] {
        switch recurrence {
        case .none: return [calendar.startOfDay(for: firstDate)]
        case .daily: return (0..<7).map { firstDate.addingDays($0, calendar: calendar) }
        case .weekly: return (0..<4).map { firstDate.addingWeeks($0, calendar: calendar) }
        case .monthly: return (0..<4).map { firstDate.addingMonths($0, calendar: calendar) }
        }
    }
}

enum ReviewWindow: String, CaseIterable, Identifiable {
    case day
    case week
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day: return "Daily review"
        case .week: return "Weekly review"
        case .month: return "Monthly review"
        }
    }
}

struct ReviewMetric: Identifiable, Equatable {
    var id: String { label }
    var label: String
    var value: String
    var progress: Double
}

struct ReviewSummary: Equatable {
    var title: String
    var wins: [String] = []
    var attention: [String] = []
    var metrics: [ReviewMetric] = []
}

enum ReviewAnalytics {
    static func build(
        window: ReviewWindow,
        anchor: Date,
        tasks: [LifeTask],
        habitLogs: [HabitLog],
        expenses: [Expense],
        fitnessHistory: [WorkoutHistoryItem],
        journals: [JournalEntry],
        calendar: Calendar = .current
    ) -> ReviewSummary {
        let range = dateRange(for: window, anchor: anchor, calendar: calendar)
        let periodTasks = tasks.filter { task in
            guard let due = task.dueDate else { return false }
            return range.contains(calendar.startOfDay(for: due))
        }
        let completedTasks = periodTasks.filter { $0.status == .done }.count
        let periodLogs = habitLogs.filter { range.contains(calendar.startOfDay(for: $0.date)) }
        let periodExpenses = expenses.filter { range.contains(calendar.startOfDay(for: $0.date)) }
        let periodFitness = fitnessHistory.filter { range.contains(calendar.startOfDay(for: $0.date)) }
        let periodJournals = journals.filter { range.contains(calendar.startOfDay(for: $0.date)) }
        let spendingMinor = periodExpenses.reduce(0) { $0 + $1.amountMinor }
        let fitnessVolume = periodFitness.reduce(0) { $0 + $1.totalVolume }
        let moodRatings = periodJournals.compactMap(\.moodRating)
        let moodAverage = moodRatings.isEmpty ? nil : Double(moodRatings.reduce(0, +)) / Double(moodRatings.count)

        var wins: [String] = []
        if completedTasks > 0 { wins.append("\(completedTasks) \(plural("task", completedTasks)) completed") }
        if !periodLogs.isEmpty { wins.append("\(periodLogs.count) habit \(plural("check", periodLogs.count)) logged") }
        if !periodFitness.isEmpty { wins.append("\(periodFitness.count) workout \(plural("session", periodFitness.count)) recorded") }
        if !periodJournals.isEmpty { wins.append("\(periodJournals.count) journal \(plural("entry", periodJournals.count)) written") }

        var attention: [String] = []
        let openTasks = periodTasks.count - completedTasks
        if openTasks > 0 { attention.append("\(openTasks) open \(plural("task", openTasks)) still need attention") }
        if periodLogs.isEmpty { attention.append("No habits logged in this window") }
        if periodJournals.isEmpty { attention.append("No journal entries in this window") }

        return ReviewSummary(
            title: window.title,
            wins: wins.isEmpty ? ["No wins logged yet"] : wins,
            attention: attention.isEmpty ? ["Everything in this window looks steady"] : attention,
            metrics: [
                ReviewMetric(label: "Tasks", value: "\(completedTasks)/\(periodTasks.count)", progress: LifeMetrics.completionPercent(completed: completedTasks, total: periodTasks.count)),
                ReviewMetric(label: "Habit logs", value: "\(periodLogs.count)", progress: min(Double(periodLogs.count) / expectedHabitLogScale(for: window), 1)),
                ReviewMetric(label: "Spending", value: moneyText(spendingMinor), progress: 0),
                ReviewMetric(label: "Fitness volume", value: volumeText(fitnessVolume), progress: min(fitnessVolume / 1_000, 1)),
                ReviewMetric(label: "Mood", value: moodAverage.map { String(format: "%.1f", $0) } ?? "--", progress: moodAverage.map { min($0 / 5, 1) } ?? 0)
            ]
        )
    }

    private static func dateRange(for window: ReviewWindow, anchor: Date, calendar: Calendar) -> ClosedRange<Date> {
        let day = calendar.startOfDay(for: anchor)
        switch window {
        case .day:
            return day...day
        case .week:
            let weekday = calendar.component(.weekday, from: day)
            let offsetFromMonday = (weekday + 5) % 7
            let start = calendar.date(byAdding: .day, value: -offsetFromMonday, to: day) ?? day
            return start...start.addingDays(6, calendar: calendar)
        case .month:
            let components = calendar.dateComponents([.year, .month], from: day)
            let start = calendar.date(from: components) ?? day
            let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start) ?? start
            return start...end
        }
    }

    private static func expectedHabitLogScale(for window: ReviewWindow) -> Double {
        switch window {
        case .day: return 4
        case .week: return 21
        case .month: return 90
        }
    }
}

struct TrendSnapshot: Equatable {
    var habitCompletion: Double = 0
    var taskCompletion: Double = 0
    var moodAverage: Double?
    var spendingMinor: Int = 0
    var spending: String = "0.00"
    var fitnessVolume: Double = 0
    var fitnessVolumeLabel: String = "0 kg"
}

enum TrendDashboard {
    static func build(
        completedHabits: Int,
        totalHabits: Int,
        completedTasks: Int,
        totalTasks: Int,
        moodRatings: [Int],
        spendingMinor: Int,
        fitnessVolume: Double
    ) -> TrendSnapshot {
        let average = moodRatings.isEmpty ? nil : Double(moodRatings.reduce(0, +)) / Double(moodRatings.count)
        return TrendSnapshot(
            habitCompletion: LifeMetrics.completionPercent(completed: completedHabits, total: totalHabits),
            taskCompletion: LifeMetrics.completionPercent(completed: completedTasks, total: totalTasks),
            moodAverage: average,
            spendingMinor: spendingMinor,
            spending: moneyText(spendingMinor),
            fitnessVolume: fitnessVolume,
            fitnessVolumeLabel: volumeText(fitnessVolume)
        )
    }
}

enum FocusSessionLogic {
    static func formatRemaining(totalSeconds: Int) -> String {
        let safeSeconds = max(totalSeconds, 0)
        return String(format: "%02d:%02d", safeSeconds / 60, safeSeconds % 60)
    }

    static func progress(totalSeconds: Int, remainingSeconds: Int) -> Double {
        guard totalSeconds > 0 else { return 0 }
        let elapsed = min(max(totalSeconds - remainingSeconds, 0), totalSeconds)
        return min(max(Double(elapsed) / Double(totalSeconds), 0), 1)
    }
}

struct WorkoutHistoryItem: Identifiable, Equatable {
    var id: UUID { sessionID }
    var sessionID: UUID
    var date: Date
    var title: String
    var setCount: Int
    var totalVolume: Double
}

enum FitnessAnalytics {
    static func workoutHistory(sessions: [WorkoutSession], sets: [WorkoutSet]) -> [WorkoutHistoryItem] {
        let setsBySession = Dictionary(grouping: sets, by: \.sessionID)
        return sessions.compactMap { session in
            let sessionSets = setsBySession[session.id] ?? []
            guard !sessionSets.isEmpty else { return nil }
            return WorkoutHistoryItem(
                sessionID: session.id,
                date: session.date,
                title: session.title,
                setCount: sessionSets.count,
                totalVolume: sessionSets.reduce(0) { $0 + Double($1.reps) * $1.weight }
            )
        }
        .sorted {
            if $0.date == $1.date { return $0.sessionID.uuidString > $1.sessionID.uuidString }
            return $0.date > $1.date
        }
    }
}

struct MoodTrend: Equatable {
    var averageRating: Double?
    var entriesWithMood: Int
    var currentWritingStreak: Int
    var recentMoodRatings: [Int] = []
}

enum JournalAnalytics {
    static func moodTrend(entries: [JournalEntry], today: Date = Date(), calendar: Calendar = .current) -> MoodTrend {
        let ratings = entries.compactMap(\.moodRating)
        let streak = LifeMetrics.habitStreak(for: entries.map(\.date), today: today, calendar: calendar)
        let recent = entries.sorted { $0.date < $1.date }.suffix(14).compactMap(\.moodRating)
        return MoodTrend(
            averageRating: ratings.isEmpty ? nil : Double(ratings.reduce(0, +)) / Double(ratings.count),
            entriesWithMood: ratings.count,
            currentWritingStreak: streak,
            recentMoodRatings: recent
        )
    }
}

struct DashboardSummary: Equatable {
    var date: Date
    var completedHabits: Int = 0
    var totalHabits: Int = 0
    var completedTasks: Int = 0
    var totalTasks: Int = 0
    var moodRating: Int?
    var moodEmoji: String?
    var upcomingReminders: [Reminder] = []
    var commandItems: [CommandSearchItem] = []
    var smartPlan: [SmartPlanItem] = []
    var dailyReview: ReviewSummary = ReviewSummary(title: "Daily review")
    var weeklyReview: ReviewSummary = ReviewSummary(title: "Weekly review")
    var monthlyReview: ReviewSummary = ReviewSummary(title: "Monthly review")
    var trends: TrendSnapshot = TrendSnapshot()
}

enum DashboardBuilder {
    static func build(state: LifeOSState, today: Date = Date(), calendar: Calendar = .current) -> DashboardSummary {
        let day = calendar.startOfDay(for: today)
        let logsToday = state.habitLogs.filter { calendar.isDate($0.date, inSameDayAs: day) }
        let completedHabitIDs = Set(logsToday.map(\.habitID))
        let activeHabits = state.habits.filter(\.isActive)
        let todaysTasks = state.tasks.filter { task in
            guard let due = task.dueDate else { return false }
            return calendar.isDate(due, inSameDayAs: day)
        }
        let completedTasks = todaysTasks.filter { $0.status == .done }.count
        let todaysEvents = state.events.filter { calendar.isDate($0.date, inSameDayAs: day) }
        let monthRange = calendar.monthRange(containing: day)
        let monthExpenses = state.expenses.filter { monthRange.contains(calendar.startOfDay(for: $0.date)) }
        let fitnessHistory = FitnessAnalytics.workoutHistory(sessions: state.workoutSessions, sets: state.workoutSets)
        let todaySets = todaysWorkoutSetCount(state: state, today: day, calendar: calendar)
        let todayJournal = state.journalEntries.first { calendar.isDate($0.date, inSameDayAs: day) }
        let recentJournals = state.journalEntries.sorted { $0.date > $1.date }.prefix(90).map { $0 }
        let moodRatings = recentJournals.compactMap(\.moodRating)
        let upcoming = state.reminders
            .filter { $0.enabled && $0.scheduledAt >= Date() }
            .sorted { $0.scheduledAt < $1.scheduledAt }

        return DashboardSummary(
            date: day,
            completedHabits: activeHabits.filter { completedHabitIDs.contains($0.id) }.count,
            totalHabits: activeHabits.count,
            completedTasks: completedTasks,
            totalTasks: todaysTasks.count,
            moodRating: todayJournal?.moodRating,
            moodEmoji: todayJournal?.moodEmoji,
            upcomingReminders: Array(upcoming.prefix(3)),
            commandItems: buildCommandItems(state: state, fitnessHistory: fitnessHistory),
            smartPlan: SmartDailyPlan.build(
                today: day,
                tasks: state.tasks,
                habits: activeHabits,
                habitLogsToday: logsToday,
                events: todaysEvents,
                reminders: Array(upcoming.prefix(8)),
                workoutsToday: todaySets,
                readingItems: state.readingItems,
                calendar: calendar
            ),
            dailyReview: ReviewAnalytics.build(window: .day, anchor: day, tasks: state.tasks, habitLogs: state.habitLogs, expenses: monthExpenses, fitnessHistory: fitnessHistory, journals: Array(recentJournals), calendar: calendar),
            weeklyReview: ReviewAnalytics.build(window: .week, anchor: day, tasks: state.tasks, habitLogs: state.habitLogs, expenses: monthExpenses, fitnessHistory: fitnessHistory, journals: Array(recentJournals), calendar: calendar),
            monthlyReview: ReviewAnalytics.build(window: .month, anchor: day, tasks: state.tasks, habitLogs: state.habitLogs, expenses: monthExpenses, fitnessHistory: fitnessHistory, journals: Array(recentJournals), calendar: calendar),
            trends: TrendDashboard.build(
                completedHabits: logsToday.count,
                totalHabits: activeHabits.count,
                completedTasks: completedTasks,
                totalTasks: todaysTasks.count,
                moodRatings: moodRatings,
                spendingMinor: monthExpenses.reduce(0) { $0 + $1.amountMinor },
                fitnessVolume: fitnessHistory.reduce(0) { $0 + $1.totalVolume }
            )
        )
    }

    static func buildCommandItems(state: LifeOSState, fitnessHistory: [WorkoutHistoryItem]) -> [CommandSearchItem] {
        let actions = [
            CommandSearchItem(title: "Quick capture", subtitle: "Add a task, event, habit, note, reading item, or focus idea", route: .dashboard, type: .action, keywords: ["create", "new", "template"]),
            CommandSearchItem(title: "Smart daily plan", subtitle: "Today across tasks, habits, reminders, events, workouts, and reading", route: .dashboard, type: .action, keywords: ["plan", "today"]),
            CommandSearchItem(title: "Review mode", subtitle: "Daily, weekly, and monthly reflection", route: .dashboard, type: .action, keywords: ["retro", "progress"]),
            CommandSearchItem(title: "Focus session", subtitle: "Start a customizable focus timer", route: .dashboard, type: .action, keywords: ["timer", "pomodoro"]),
            CommandSearchItem(title: "Privacy controls", subtitle: "Hide sensitive previews and tune widgets", route: .settings, type: .setting, keywords: ["widget", "lock", "private"]),
            CommandSearchItem(title: "Customize layout", subtitle: "Hide or reorder sections across the app", route: .settings, type: .setting, keywords: ["customise", "reorder"])
        ]

        let taskItems = state.tasks.prefix(60).map {
            CommandSearchItem(title: $0.title, subtitle: $0.notes.isEmpty ? ($0.dueDate?.lifeOSDayString ?? "Task") : $0.notes, route: .tasks, type: .task)
        }
        let habitItems = state.habits.map {
            CommandSearchItem(title: $0.title, subtitle: $0.description.isEmpty ? "Habit" : $0.description, route: .habits, type: .habit)
        }
        let eventItems = state.events.prefix(60).map {
            CommandSearchItem(title: $0.title, subtitle: "\($0.category) - \($0.date.lifeOSDayString)", route: .calendar, type: .event, keywords: [$0.notes])
        }
        let expenseItems = state.expenses.prefix(40).map {
            CommandSearchItem(title: $0.notes.isEmpty ? "Expense" : $0.notes, subtitle: "\(Double($0.amountMinor) / 100) \($0.currency)", route: .expenses, type: .expense)
        }
        let fitnessItems = fitnessHistory.prefix(20).map {
            CommandSearchItem(title: $0.title, subtitle: "\($0.setCount) sets - \(Int($0.totalVolume)) kg", route: .fitness, type: .workout)
        }
        let journalItems = state.journalEntries.prefix(20).map {
            CommandSearchItem(title: $0.body.firstLineOr("Journal entry"), subtitle: $0.date.lifeOSDayString, route: .journal, type: .journal, keywords: [$0.prompt, $0.moodEmoji ?? ""])
        }
        let readingItems = state.readingItems
            .filter { $0.status != .archived }
            .prefix(40)
            .map {
                CommandSearchItem(title: $0.title, subtitle: $0.sourceLabel.isEmpty ? $0.type.rawValue.lowercased() : $0.sourceLabel, route: .journal, type: .reading, keywords: [$0.notes])
            }
        let noteItems = state.notes
            .filter { $0.deletedAt == nil }
            .prefix(40)
            .map {
                CommandSearchItem(title: $0.title.isEmpty ? "Untitled note" : $0.title, subtitle: $0.body.firstLineOr("Note"), route: .notes, type: .note)
            }

        return actions + taskItems + habitItems + eventItems + expenseItems + fitnessItems + journalItems + readingItems + noteItems
    }

    private static func todaysWorkoutSetCount(state: LifeOSState, today: Date, calendar: Calendar) -> Int {
        let sessions = state.workoutSessions.filter { calendar.isDate($0.date, inSameDayAs: today) }.map(\.id)
        return state.workoutSets.filter { sessions.contains($0.sessionID) }.count
    }
}

struct QuickCaptureResult: Equatable {
    var success: Bool
    var message: String
}

func moneyText(_ amountMinor: Int) -> String {
    String(format: "%.2f", Double(amountMinor) / 100)
}

func volumeText(_ volume: Double) -> String {
    "\(Int(volume.rounded())) kg"
}

private func plural(_ word: String, _ count: Int) -> String {
    count == 1 ? word : "\(word)s"
}

private extension String {
    var normalizedSearchText: String {
        lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func firstLineOr(_ fallback: String) -> String {
        split(separator: "\n").first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines).prefix(64) }
            .map(String.init) ?? fallback
    }
}

private extension TaskPriority {
    var sortRank: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        case .urgent: return 3
        }
    }
}

private extension Calendar {
    func monthRange(containing date: Date) -> ClosedRange<Date> {
        let components = dateComponents([.year, .month], from: date)
        let start = self.date(from: components) ?? startOfDay(for: date)
        let end = self.date(byAdding: DateComponents(month: 1, day: -1), to: start) ?? start
        return start...end
    }
}
