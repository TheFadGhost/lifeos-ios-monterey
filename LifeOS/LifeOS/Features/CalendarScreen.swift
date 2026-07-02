import SwiftUI

struct CalendarScreen: View {
    @EnvironmentObject private var store: LifeOSStore
    let tokens: LifeOSThemeTokens

    @State private var selectedDate = Date()
    @State private var eventTitle = ""
    @State private var eventNotes = ""
    @State private var category = "General"

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                datePickerCard
                addEventCard
                selectedDaySummary
                eventList
            }
            .lifeOSScreenPadding()
        }
    }

    private var datePickerCard: some View {
        LifeOSCard(tokens: tokens) {
            SectionTitle("Calendar", subtitle: "App-only local calendar", tokens: tokens)
            DatePicker("Selected day", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(tokens.accent)
        }
    }

    private var addEventCard: some View {
        LifeOSCard(tokens: tokens) {
            SectionTitle("Add Event", subtitle: selectedDate.lifeOSDayString, tokens: tokens)
            LifeTextField(title: "Event title", text: $eventTitle, tokens: tokens)
            LifeTextField(title: "Notes", text: $eventNotes, tokens: tokens, axis: .vertical)
            LifeTextField(title: "Category", text: $category, tokens: tokens)
            LifeButton(title: "Add Event", systemImage: "calendar.badge.plus", tokens: tokens) {
                store.addEvent(title: eventTitle, notes: eventNotes, date: selectedDate, category: category.trimmedNonEmpty ?? "General")
                eventTitle = ""
                eventNotes = ""
            }
        }
    }

    private var selectedDaySummary: some View {
        let tasks = store.state.tasks.filter { $0.dueDate?.isSameDay(as: selectedDate) == true }
        let habitLogs = store.state.habitLogs.filter { $0.date.isSameDay(as: selectedDate) }
        let expenses = store.state.expenses.filter { $0.date.isSameDay(as: selectedDate) }
        let sessions = store.state.workoutSessions.filter { $0.date.isSameDay(as: selectedDate) }
        let journal = store.state.journalEntries.first { $0.date.isSameDay(as: selectedDate) }

        return LifeOSCard(tokens: tokens) {
            SectionTitle("Selected Day", subtitle: selectedDate.formatted(date: .complete, time: .omitted), tokens: tokens)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                MetricTile(title: "Tasks", value: "\(tasks.count)", subtitle: "Due", progress: LifeMetrics.completionPercent(completed: tasks.filter { $0.status == .done }.count, total: tasks.count), tokens: tokens)
                MetricTile(title: "Habits", value: "\(habitLogs.count)", subtitle: "Logged", progress: min(Double(habitLogs.count) / 4, 1), tokens: tokens)
                MetricTile(title: "Spending", value: "£\(moneyText(expenses.reduce(0) { $0 + $1.amountMinor }))", subtitle: "Logged", progress: 0, tokens: tokens)
                MetricTile(title: "Fitness", value: "\(sessions.count)", subtitle: "Sessions", progress: min(Double(sessions.count), 1), tokens: tokens)
                MetricTile(title: "Mood", value: journal?.moodRating.map { "\($0)/5" } ?? "--", subtitle: journal?.moodEmoji ?? "Journal", progress: Double(journal?.moodRating ?? 0) / 5, tokens: tokens)
            }
        }
    }

    private var eventList: some View {
        let events = store.state.events
            .filter { $0.date.isSameDay(as: selectedDate) }
            .sorted { ($0.startTimeMinutes ?? 0) < ($1.startTimeMinutes ?? 0) }

        return LifeOSCard(tokens: tokens) {
            SectionTitle("Events", subtitle: "\(events.count) on this day", tokens: tokens)
            if events.isEmpty {
                EmptyState(title: "No events", subtitle: "Add an app-only event for this day.", tokens: tokens)
            } else {
                ForEach(events) { event in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(event.title)
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(tokens.primaryText)
                            Text("\(event.category) · \(event.notes.isEmpty ? "No notes" : event.notes)")
                                .font(.caption)
                                .foregroundStyle(tokens.secondaryText)
                                .lineLimit(2)
                        }
                        Spacer()
                        Button(role: .destructive) {
                            store.deleteEvent(event.id)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(tokens.danger)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .background(tokens.elevatedSurface.opacity(0.58))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }
}
