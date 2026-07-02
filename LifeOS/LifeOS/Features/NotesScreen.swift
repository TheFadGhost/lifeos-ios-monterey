import SwiftUI

struct NotesScreen: View {
    @EnvironmentObject private var store: LifeOSStore
    let tokens: LifeOSThemeTokens

    @State private var title = ""
    @State private var bodyText = ""
    @State private var searchText = ""
    @State private var editingNote: LifeNote?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                addNote
                search
                noteList
            }
            .lifeOSScreenPadding()
        }
        .sheet(item: $editingNote) { note in
            NoteEditSheet(note: note, tokens: tokens)
                .environmentObject(store)
        }
    }

    private var addNote: some View {
        LifeOSCard(tokens: tokens) {
            SectionTitle("Notes", subtitle: "Local notes, daily notes, pinning, soft delete", tokens: tokens)
            LifeTextField(title: "Title", text: $title, tokens: tokens)
            LifeTextField(title: "Body", text: $bodyText, tokens: tokens, axis: .vertical)
            HStack {
                LifeButton(title: "Add Note", systemImage: "note.text.badge.plus", tokens: tokens) {
                    store.addNote(title: title, body: bodyText)
                    title = ""
                    bodyText = ""
                }
                LifeButton(title: "Daily", systemImage: "calendar", tokens: tokens) {
                    store.addNote(title: "Daily \(Date().lifeOSDayString)", body: bodyText, isDaily: true, dailyDate: Date())
                    title = ""
                    bodyText = ""
                }
            }
        }
    }

    private var search: some View {
        LifeOSCard(tokens: tokens) {
            SectionTitle("Search Notes", subtitle: "Title and body", tokens: tokens)
            LifeTextField(title: "Search", text: $searchText, tokens: tokens)
        }
    }

    private var noteList: some View {
        let notes = store.state.notes
            .filter { $0.deletedAt == nil }
            .filter { note in
                SearchFilters.matchesText([note.title, note.body], query: searchText)
            }
            .sorted {
                if $0.isPinned != $1.isPinned { return $0.isPinned && !$1.isPinned }
                return $0.updatedAt > $1.updatedAt
            }

        return LifeOSCard(tokens: tokens) {
            SectionTitle("All Notes", subtitle: "\(notes.count) visible", tokens: tokens)
            if notes.isEmpty {
                EmptyState(title: "No notes", subtitle: "Capture a note or daily page.", tokens: tokens)
            } else {
                ForEach(notes) { note in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                if note.isPinned {
                                    Image(systemName: "pin.fill").foregroundStyle(tokens.accent)
                                }
                                Text(note.title)
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(tokens.primaryText)
                            }
                            Text(note.body.isEmpty ? "No body" : note.body)
                                .font(.caption)
                                .foregroundStyle(tokens.secondaryText)
                                .lineLimit(3)
                            Text("\(note.wordCount) words · \(note.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption2)
                                .foregroundStyle(tokens.secondaryText)
                        }
                        Spacer()
                        Menu {
                            Button("Edit") { editingNote = note }
                            Button("Delete", role: .destructive) { store.deleteNote(note.id) }
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
    }
}

private struct NoteEditSheet: View {
    @EnvironmentObject private var store: LifeOSStore
    @Environment(\.dismiss) private var dismiss
    let note: LifeNote
    let tokens: LifeOSThemeTokens

    @State private var title: String
    @State private var bodyText: String
    @State private var isPinned: Bool

    init(note: LifeNote, tokens: LifeOSThemeTokens) {
        self.note = note
        self.tokens = tokens
        _title = State(initialValue: note.title)
        _bodyText = State(initialValue: note.body)
        _isPinned = State(initialValue: note.isPinned)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LifeOSBackground(tokens: tokens)
                VStack(spacing: 12) {
                    LifeTextField(title: "Title", text: $title, tokens: tokens)
                    LifeTextField(title: "Body", text: $bodyText, tokens: tokens, axis: .vertical)
                    Toggle("Pinned", isOn: $isPinned)
                        .foregroundStyle(tokens.primaryText)
                    LifeButton(title: "Save", systemImage: "checkmark", tokens: tokens) {
                        store.updateNote(note.id, title: title, body: bodyText, isPinned: isPinned)
                        dismiss()
                    }
                }
                .padding()
            }
            .navigationTitle("Edit Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
