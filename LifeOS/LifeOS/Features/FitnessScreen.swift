import SwiftUI

struct FitnessScreen: View {
    @EnvironmentObject private var store: LifeOSStore
    let tokens: LifeOSThemeTokens

    @State private var selectedExerciseID: UUID?
    @State private var reps = "10"
    @State private var weight = "0"

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                logSetCard
                exerciseLibrary
                historyCard
            }
            .lifeOSScreenPadding()
        }
        .onAppear {
            selectedExerciseID = selectedExerciseID ?? store.state.exercises.first?.id
        }
    }

    private var logSetCard: some View {
        LifeOSCard(tokens: tokens) {
            SectionTitle("Fitness", subtitle: "Exercise library, set logging, history", tokens: tokens)
            Picker("Exercise", selection: $selectedExerciseID) {
                ForEach(sortedExercises) { exercise in
                    Text(exercise.name).tag(Optional(exercise.id))
                }
            }
            LifeTextField(title: "Reps", text: $reps, tokens: tokens)
                .keyboardType(.numberPad)
            LifeTextField(title: "Weight kg", text: $weight, tokens: tokens)
                .keyboardType(.decimalPad)
            LifeButton(title: "Log Set", systemImage: "plus.circle.fill", tokens: tokens) {
                guard let selectedExerciseID else { return }
                store.logWorkoutSet(exerciseID: selectedExerciseID, reps: Int(reps) ?? 0, weight: Double(weight) ?? 0)
            }
        }
    }

    private var exerciseLibrary: some View {
        LifeOSCard(tokens: tokens) {
            SectionTitle("Exercise Library", subtitle: "\(store.state.exercises.count) seeded exercises", tokens: tokens)
            ForEach(exerciseLibraryGroups) { section in
                exerciseGroupSection(section)
            }
        }
    }

    private var historyCard: some View {
        let history = workoutHistory
        return LifeOSCard(tokens: tokens) {
            SectionTitle("Workout History", subtitle: "\(history.count) sessions", tokens: tokens)
            if history.isEmpty {
                EmptyState(title: "No sessions", subtitle: "Log a set to create today's session.", tokens: tokens)
            } else {
                ForEach(history) { item in
                    historyItem(item)
                }
            }
        }
    }

    private var sortedExercises: [Exercise] {
        store.state.exercises.sorted { $0.name < $1.name }
    }

    private var exerciseLibraryGroups: [FitnessExerciseGroup] {
        store.state.muscleGroups
            .sorted { $0.sortOrder < $1.sortOrder }
            .compactMap { group in
                let exercises = store.state.exercises.filter { $0.muscleGroupID == group.id }
                return exercises.isEmpty ? nil : FitnessExerciseGroup(group: group, exercises: exercises)
            }
    }

    private var workoutHistory: [WorkoutHistoryItem] {
        FitnessAnalytics.workoutHistory(sessions: store.state.workoutSessions, sets: store.state.workoutSets)
    }

    private func exerciseGroupSection(_ section: FitnessExerciseGroup) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.group.name)
                .font(.caption.weight(.bold))
                .foregroundStyle(tokens.secondaryText)
            ForEach(section.exercises) { exercise in
                exerciseRow(exercise)
            }
        }
    }

    private func exerciseRow(_ exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(exercise.name)
                .font(.callout.weight(.semibold))
                .foregroundStyle(tokens.primaryText)
            Text(exercise.instructions)
                .font(.caption)
                .foregroundStyle(tokens.secondaryText)
        }
        .padding(10)
        .background(tokens.elevatedSurface.opacity(0.52))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func historyItem(_ item: WorkoutHistoryItem) -> some View {
        DisclosureGroup {
            ForEach(workoutSets(for: item)) { set in
                historySetRow(set)
            }
        } label: {
            historyItemLabel(item)
        }
        .padding(10)
        .background(tokens.elevatedSurface.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func historySetRow(_ set: WorkoutSet) -> some View {
        HStack {
            Text("\(exerciseName(for: set)) - \(set.reps)x\(set.weight, specifier: "%.1f")kg")
                .font(.caption)
                .foregroundStyle(tokens.primaryText)
            Spacer()
            Button(role: .destructive) {
                store.deleteWorkoutSet(set.id)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(tokens.danger)
            }
            .buttonStyle(.plain)
        }
    }

    private func historyItemLabel(_ item: WorkoutHistoryItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(tokens.primaryText)
                Text("\(item.date.lifeOSDayString) - \(item.setCount) sets")
                    .font(.caption)
                    .foregroundStyle(tokens.secondaryText)
            }
            Spacer()
            Text(volumeText(item.totalVolume))
                .font(.callout.weight(.semibold))
                .foregroundStyle(tokens.accent)
        }
    }

    private func workoutSets(for item: WorkoutHistoryItem) -> [WorkoutSet] {
        store.state.workoutSets.filter { $0.sessionID == item.sessionID }
    }

    private func exerciseName(for set: WorkoutSet) -> String {
        store.state.exercises.first { $0.id == set.exerciseID }?.name ?? "Exercise"
    }
}

private struct FitnessExerciseGroup: Identifiable {
    let group: MuscleGroup
    let exercises: [Exercise]

    var id: UUID {
        group.id
    }
}
