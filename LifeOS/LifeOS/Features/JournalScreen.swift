import SwiftUI

struct JournalScreen: View {
    @EnvironmentObject private var store: LifeOSStore
    let tokens: LifeOSThemeTokens

    @State private var bodyText = ""
    @State private var moodRating = 3
    @State private var moodEmoji = "🙂"
    @State private var readingTitle = ""
    @State private var readingType: ReadingType = .other

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                journalEditor
                moodTrend
                readingList
                recentEntries
            }
            .lifeOSScreenPadding()
        }
        .onAppear(perform: loadTodayJournal)
    }

    private var journalEditor: some View {
        LifeOSCard(tokens: tokens) {
            SectionTitle("Level Up", subtitle: "Journal, mood, reading/watch list", tokens: tokens)
            LifeTextField(title: "What went well today?", text: $bodyText, tokens: tokens, axis: .vertical)
            Stepper("Mood: \(moodRating)/5", value: $moodRating, in: 1...5)
                .foregroundStyle(tokens.primaryText)
            LifeTextField(title: "Mood emoji", text: $moodEmoji, tokens: tokens)
            LifeButton(title: "Save Journal", systemImage: "square.and.arrow.down.fill", tokens: tokens) {
                store.saveJournal(date: Date(), body: bodyText, moodRating: moodRating, moodEmoji: moodEmoji)
            }
        }
    }

    private var moodTrend: some View {
        let trend = JournalAnalytics.moodTrend(entries: store.state.journalEntries)
        return LifeOSCard(tokens: tokens) {
            SectionTitle("Mood Trend", subtitle: "Average, streak, recent ratings", tokens: tokens)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                MetricTile(title: "Average", value: trend.averageRating.map { String(format: "%.1f", $0) } ?? "--", subtitle: "\(trend.entriesWithMood) rated entries", progress: (trend.averageRating ?? 0) / 5, tokens: tokens)
                MetricTile(title: "Writing streak", value: "\(trend.currentWritingStreak)", subtitle: "Days", progress: min(Double(trend.currentWritingStreak) / 7, 1), tokens: tokens)
            }
            if !trend.recentMoodRatings.isEmpty {
                HStack(alignment: .bottom, spacing: 5) {
                    ForEach(Array(trend.recentMoodRatings.enumerated()), id: \.offset) { _, rating in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(tokens.accent)
                            .frame(height: CGFloat(rating) * 12)
                    }
                }
                .frame(height: 68, alignment: .bottom)
            }
        }
    }

    private var readingList: some View {
        LifeOSCard(tokens: tokens) {
            SectionTitle("Reading / Watch List", subtitle: "Saved, in progress, completed, archived", tokens: tokens)
            LifeTextField(title: "Title", text: $readingTitle, tokens: tokens)
            Picker("Type", selection: $readingType) {
                ForEach(ReadingType.allCases) { type in
                    Text(type.label).tag(type)
                }
            }
            .pickerStyle(.segmented)
            LifeButton(title: "Add Item", systemImage: "plus.circle.fill", tokens: tokens) {
                store.addReadingItem(title: readingTitle, type: readingType)
                readingTitle = ""
            }

            ForEach(store.state.readingItems.filter { $0.status != .archived }.sorted { $0.createdAt > $1.createdAt }) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(tokens.primaryText)
                        Text("\(item.type.label) · \(item.status.label)")
                            .font(.caption)
                            .foregroundStyle(tokens.secondaryText)
                    }
                    Spacer()
                    Menu {
                        ForEach(ReadingStatus.allCases) { status in
                            Button(status.label) { store.updateReadingStatus(item.id, status: status) }
                        }
                        Button("Delete", role: .destructive) { store.deleteReadingItem(item.id) }
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
    }

    private var recentEntries: some View {
        let entries = store.state.journalEntries.sorted { $0.date > $1.date }.prefix(10)
        return LifeOSCard(tokens: tokens) {
            SectionTitle("Recent Journal", subtitle: "\(entries.count) entries", tokens: tokens)
            if entries.isEmpty {
                EmptyState(title: "No entries", subtitle: "Write today's journal to begin.", tokens: tokens)
            } else {
                ForEach(Array(entries)) { entry in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.date.lifeOSDayString)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(tokens.secondaryText)
                        Text(entry.body.isEmpty ? "Empty journal entry" : entry.body)
                            .font(.callout)
                            .foregroundStyle(tokens.primaryText)
                            .lineLimit(3)
                    }
                    .padding(10)
                    .background(tokens.elevatedSurface.opacity(0.58))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }

    private func loadTodayJournal() {
        if let entry = store.state.journalEntries.first(where: { Calendar.current.isDateInToday($0.date) }) {
            bodyText = entry.body
            moodRating = entry.moodRating ?? 3
            moodEmoji = entry.moodEmoji ?? "🙂"
        }
    }
}
