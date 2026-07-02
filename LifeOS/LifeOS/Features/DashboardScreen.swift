import SwiftUI

struct DashboardScreen: View {
    @EnvironmentObject private var store: LifeOSStore
    let tokens: LifeOSThemeTokens
    let openRoute: (LifeRoute) -> Void

    @State private var searchText = ""
    @State private var quickCaptureText = ""
    @State private var quickCaptureMessage = ""
    @State private var focusSeconds = 25 * 60
    @State private var focusRemaining = 25 * 60
    @State private var focusRunning = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        let summary = DashboardBuilder.build(state: store.state)
        let privateMode = store.state.settings.privacyMode

        ScrollView {
            VStack(spacing: 14) {
                overview(summary: summary, privateMode: privateMode)
                commandSearch(summary: summary)
                quickCapture()
                smartPlan(summary: summary, privateMode: privateMode)
                review(summary.dailyReview)
                trends(summary.trends)
                focusTimer()
                reminders(summary.upcomingReminders, privateMode: privateMode)
                moduleGrid()
            }
            .lifeOSScreenPadding()
        }
        .onReceive(timer) { _ in
            guard focusRunning else { return }
            focusRemaining = max(0, focusRemaining - 1)
            if focusRemaining == 0 {
                focusRunning = false
            }
        }
    }

    private func overview(summary: DashboardSummary, privateMode: Bool) -> some View {
        LifeOSCard(tokens: tokens) {
            SectionTitle("Command Center", subtitle: privateMode ? "Private mode is hiding sensitive text" : "Offline dashboard across your day", tokens: tokens)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                MetricTile(
                    title: "Habits",
                    value: "\(summary.completedHabits)/\(summary.totalHabits)",
                    subtitle: "Done today",
                    progress: LifeMetrics.completionPercent(completed: summary.completedHabits, total: summary.totalHabits),
                    tokens: tokens
                )
                MetricTile(
                    title: "Tasks",
                    value: "\(summary.completedTasks)/\(summary.totalTasks)",
                    subtitle: "Due today",
                    progress: LifeMetrics.completionPercent(completed: summary.completedTasks, total: summary.totalTasks),
                    tokens: tokens
                )
                MetricTile(
                    title: "Mood",
                    value: privateMode ? "Hidden" : (summary.moodRating.map { "\($0)/5" } ?? "--"),
                    subtitle: summary.moodEmoji ?? "Journal state",
                    progress: Double(summary.moodRating ?? 0) / 5,
                    tokens: tokens
                )
                MetricTile(
                    title: "Focus",
                    value: FocusSessionLogic.formatRemaining(totalSeconds: focusRemaining),
                    subtitle: focusRunning ? "Running" : "Ready",
                    progress: FocusSessionLogic.progress(totalSeconds: focusSeconds, remainingSeconds: focusRemaining),
                    tokens: tokens
                )
            }
        }
    }

    private func commandSearch(summary: DashboardSummary) -> some View {
        let results = CommandSearch.filter(items: summary.commandItems, query: searchText)
        return LifeOSCard(tokens: tokens) {
            SectionTitle("Global Search", subtitle: "Actions, tasks, habits, events, notes, settings", tokens: tokens)
            LifeTextField(title: "Search LifeOS", text: $searchText, tokens: tokens)
            if searchText.trimmedNonEmpty == nil {
                EmptyState(title: "Start typing", subtitle: "Search stays local on this iPhone.", tokens: tokens)
            } else if results.isEmpty {
                EmptyState(title: "No matches", subtitle: "Try a task, module, setting, or note keyword.", tokens: tokens)
            } else {
                ForEach(results) { item in
                    Button {
                        openRoute(item.route)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title)
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(tokens.primaryText)
                                Text(item.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(tokens.secondaryText)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Image(systemName: item.route.systemImage)
                                .foregroundStyle(tokens.accent)
                        }
                        .padding(10)
                        .background(tokens.elevatedSurface.opacity(0.58))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func quickCapture() -> some View {
        LifeOSCard(tokens: tokens) {
            SectionTitle("Quick Capture", subtitle: "task/event/habit/journal/reading/focus, plus daily weekly monthly", tokens: tokens)
            LifeTextField(title: "Example: task revise maths daily tomorrow", text: $quickCaptureText, tokens: tokens)
            LifeButton(title: "Capture", systemImage: "plus.circle.fill", tokens: tokens) {
                let result = store.quickCapture(quickCaptureText)
                quickCaptureMessage = result.message
                if result.success {
                    quickCaptureText = ""
                }
            }
            if !quickCaptureMessage.isEmpty {
                Text(quickCaptureMessage)
                    .font(.caption)
                    .foregroundStyle(tokens.secondaryText)
            }
        }
    }

    private func smartPlan(summary: DashboardSummary, privateMode: Bool) -> some View {
        LifeOSCard(tokens: tokens) {
            SectionTitle("Smart Daily Plan", subtitle: "Overdue, today, upcoming, optional", tokens: tokens)
            if summary.smartPlan.isEmpty {
                EmptyState(title: "No plan items", subtitle: "Your day is clear for now.", tokens: tokens)
            } else {
                ForEach(summary.smartPlan) { item in
                    Button {
                        openRoute(item.route)
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Text(item.urgency.label)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(tokens.backgroundTop)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(item.urgency == .overdue ? tokens.danger : tokens.accent)
                                .clipShape(Capsule())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(privateMode ? "Hidden item" : item.title)
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(tokens.primaryText)
                                Text(privateMode ? item.route.label : item.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(tokens.secondaryText)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(tokens.elevatedSurface.opacity(0.56))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func review(_ summary: ReviewSummary) -> some View {
        LifeOSCard(tokens: tokens) {
            SectionTitle(summary.title, subtitle: "Wins, attention, and progress", tokens: tokens)
            ForEach(summary.wins, id: \.self) { win in
                Label(win, systemImage: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundStyle(tokens.primaryText)
            }
            ForEach(summary.attention, id: \.self) { item in
                Label(item, systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(tokens.secondaryText)
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(summary.metrics) { metric in
                    MetricTile(title: metric.label, value: metric.value, subtitle: "Review", progress: metric.progress, tokens: tokens)
                }
            }
        }
    }

    private func trends(_ snapshot: TrendSnapshot) -> some View {
        LifeOSCard(tokens: tokens) {
            SectionTitle("Trends", subtitle: "Habit, task, mood, money, fitness", tokens: tokens)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                MetricTile(title: "Habit completion", value: "\(Int(snapshot.habitCompletion * 100))%", subtitle: "Today", progress: snapshot.habitCompletion, tokens: tokens)
                MetricTile(title: "Task completion", value: "\(Int(snapshot.taskCompletion * 100))%", subtitle: "Today", progress: snapshot.taskCompletion, tokens: tokens)
                MetricTile(title: "Mood average", value: snapshot.moodAverage.map { String(format: "%.1f", $0) } ?? "--", subtitle: "Recent", progress: (snapshot.moodAverage ?? 0) / 5, tokens: tokens)
                MetricTile(title: "Spending", value: "£\(snapshot.spending)", subtitle: "This month", progress: 0, tokens: tokens)
                MetricTile(title: "Fitness volume", value: snapshot.fitnessVolumeLabel, subtitle: "Recent", progress: min(snapshot.fitnessVolume / 1_000, 1), tokens: tokens)
            }
        }
    }

    private func focusTimer() -> some View {
        LifeOSCard(tokens: tokens) {
            SectionTitle("Focus Session", subtitle: "Local timer, no account or sync", tokens: tokens)
            Text(FocusSessionLogic.formatRemaining(totalSeconds: focusRemaining))
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .foregroundStyle(tokens.primaryText)
                .frame(maxWidth: .infinity, alignment: .center)
            ProgressView(value: FocusSessionLogic.progress(totalSeconds: focusSeconds, remainingSeconds: focusRemaining))
                .tint(tokens.accent)
            HStack {
                LifeButton(title: focusRunning ? "Pause" : "Start", systemImage: focusRunning ? "pause.fill" : "play.fill", tokens: tokens) {
                    focusRunning.toggle()
                }
                LifeButton(title: "Reset", systemImage: "arrow.counterclockwise", tokens: tokens) {
                    focusRunning = false
                    focusRemaining = focusSeconds
                }
            }
        }
    }

    private func reminders(_ reminders: [Reminder], privateMode: Bool) -> some View {
        LifeOSCard(tokens: tokens) {
            SectionTitle("Next Reminders", subtitle: "iOS local notifications", tokens: tokens)
            if reminders.isEmpty {
                EmptyState(title: "No upcoming reminders", subtitle: "Add reminders from module records.", tokens: tokens)
            } else {
                ForEach(reminders) { reminder in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(privateMode ? "Hidden reminder" : reminder.title)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(tokens.primaryText)
                        Text(reminder.scheduledAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(tokens.secondaryText)
                    }
                }
            }
        }
    }

    private func moduleGrid() -> some View {
        LifeOSCard(tokens: tokens) {
            SectionTitle("Modules", subtitle: "Open a LifeOS area", tokens: tokens)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(LifeRoute.bottomRoutes) { route in
                    RouteButton(route: route, tokens: tokens) {
                        openRoute(route)
                    }
                }
            }
        }
    }
}
