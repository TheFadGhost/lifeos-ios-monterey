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
                ForEach(store.state.exercises.sorted { $0.name < $1.name }) { exercise in
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
            ForEach(store.state.muscleGroups.sorted { $0.sortOrder < $1.sortOrder }) { group in
                let exercises = store.state.exercises.filter { $0.muscleGroupID == group.id }
                if !exercises.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.name)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(tokens.secondaryText)
                        ForEach(exercises) { exercise in
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
                    }
                }
            }
        }
    }

    private var historyCard: some View {
        let history = FitnessAnalytics.workoutHistory(sessions: store.state.workoutSessions, sets: store.state.workoutSets)
        return LifeOSCard(tokens: tokens) {
            SectionTitle("Workout History", subtitle: "\(history.count) sessions", tokens: tokens)
            if history.isEmpty {
                EmptyState(title: "No sessions", subtitle: "Log a set to create today's session.", tokens: tokens)
            } else {
                ForEach(history) { item in
                    DisclosureGroup {
                        ForEach(store.state.workoutSets.filter { $0.sessionID == item.sessionID }) { set in
                            let exercise = store.state.exercises.first { $0.id == set.exerciseID }
                            HStack {
                                Text("\(exercise?.name ?? "Exercise") · \(set.reps)x\(set.weight, specifier: "%.1f")kg")
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
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title)
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(tokens.primaryText)
                                Text("\(item.date.lifeOSDayString) · \(item.setCount) sets")
                                    .font(.caption)
                                    .foregroundStyle(tokens.secondaryText)
                            }
                            Spacer()
                            Text(volumeText(item.totalVolume))
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(tokens.accent)
                        }
                    }
                    .padding(10)
                    .background(tokens.elevatedSurface.opacity(0.58))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }
}
