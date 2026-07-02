import SwiftUI

struct HabitsScreen: View {
    @EnvironmentObject private var store: LifeOSStore
    let tokens: LifeOSThemeTokens

    @State private var title = ""
    @State private var editingHabit: Habit?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                addHabitCard
                habitList
            }
            .lifeOSScreenPadding()
        }
        .sheet(item: $editingHabit) { habit in
            HabitEditSheet(habit: habit, tokens: tokens)
                .environmentObject(store)
        }
    }

    private var addHabitCard: some View {
        LifeOSCard(tokens: tokens) {
            SectionTitle("Habits", subtitle: "Daily check-ins and streaks", tokens: tokens)
            HStack {
                LifeTextField(title: "New habit", text: $title, tokens: tokens)
                Button {
                    store.addHabit(title: title)
                    title = ""
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .frame(width: 46, height: 46)
                        .foregroundStyle(tokens.backgroundTop)
                        .background(tokens.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var habitList: some View {
        let activeHabits = store.state.habits.filter(\.isActive).sorted { $0.sortOrder < $1.sortOrder }
        return LifeOSCard(tokens: tokens) {
            SectionTitle("Today", subtitle: "\(activeHabits.count) active habits", tokens: tokens)
            if activeHabits.isEmpty {
                EmptyState(title: "No habits", subtitle: "Add a daily habit to start tracking.", tokens: tokens)
            } else {
                ForEach(activeHabits) { habit in
                    habitRow(habit)
                }
            }
        }
    }

    private func habitRow(_ habit: Habit) -> some View {
        let completed = store.state.habitLogs.contains { $0.habitID == habit.id && Calendar.current.isDateInToday($0.date) }
        let streak = LifeMetrics.habitStreak(for: store.state.habitLogs.filter { $0.habitID == habit.id }.map(\.date))
        return HStack(spacing: 12) {
            Button {
                store.toggleHabit(habit.id)
            } label: {
                Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(completed ? tokens.accent : tokens.secondaryText)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(habit.title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(tokens.primaryText)
                Text(habit.description.isEmpty ? "\(streak) day streak" : "\(habit.description) · \(streak) day streak")
                    .font(.caption)
                    .foregroundStyle(tokens.secondaryText)
            }

            Spacer()

            Menu {
                Button("Edit") { editingHabit = habit }
                Button("Delete", role: .destructive) { store.deleteHabit(habit.id) }
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 34, height: 34)
                    .foregroundStyle(tokens.secondaryText)
            }
        }
        .padding(10)
        .background(tokens.elevatedSurface.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct HabitEditSheet: View {
    @EnvironmentObject private var store: LifeOSStore
    @Environment(\.dismiss) private var dismiss
    let habit: Habit
    let tokens: LifeOSThemeTokens

    @State private var title: String
    @State private var description: String

    init(habit: Habit, tokens: LifeOSThemeTokens) {
        self.habit = habit
        self.tokens = tokens
        _title = State(initialValue: habit.title)
        _description = State(initialValue: habit.description)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LifeOSBackground(tokens: tokens)
                VStack(spacing: 12) {
                    LifeTextField(title: "Title", text: $title, tokens: tokens)
                    LifeTextField(title: "Description", text: $description, tokens: tokens, axis: .vertical)
                    LifeButton(title: "Save", systemImage: "checkmark", tokens: tokens) {
                        store.updateHabit(habit, title: title, description: description)
                        dismiss()
                    }
                }
                .padding()
            }
            .navigationTitle("Edit Habit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
