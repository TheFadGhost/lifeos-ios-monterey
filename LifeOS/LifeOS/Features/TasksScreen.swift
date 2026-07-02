import SwiftUI

struct TasksScreen: View {
    @EnvironmentObject private var store: LifeOSStore
    let tokens: LifeOSThemeTokens

    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate = Date()
    @State private var useDueDate = true
    @State private var priority: TaskPriority = .medium
    @State private var folderID: UUID?
    @State private var searchText = ""
    @State private var statusFilter: TaskStatus?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                addTask
                filters
                taskList
            }
            .lifeOSScreenPadding()
        }
    }

    private var addTask: some View {
        LifeOSCard(tokens: tokens) {
            SectionTitle("Tasks / Goals / Studies", subtitle: "Folders, due dates, priorities, status", tokens: tokens)
            LifeTextField(title: "Task title", text: $title, tokens: tokens)
            LifeTextField(title: "Notes", text: $notes, tokens: tokens, axis: .vertical)

            Toggle("Use due date", isOn: $useDueDate)
                .foregroundStyle(tokens.primaryText)
            if useDueDate {
                DatePicker("Due", selection: $dueDate, displayedComponents: .date)
                    .foregroundStyle(tokens.primaryText)
            }

            Picker("Priority", selection: $priority) {
                ForEach(TaskPriority.allCases) { priority in
                    Text(priority.label).tag(priority)
                }
            }
            .pickerStyle(.segmented)

            Picker("Folder", selection: $folderID) {
                Text("Unfiled").tag(UUID?.none)
                ForEach(store.state.taskFolders.sorted { $0.sortOrder < $1.sortOrder }) { folder in
                    Text(folder.name).tag(Optional(folder.id))
                }
            }
            .foregroundStyle(tokens.primaryText)

            LifeButton(title: "Add Task", systemImage: "plus.circle.fill", tokens: tokens) {
                store.addTask(title: title, notes: notes, dueDate: useDueDate ? dueDate : nil, priority: priority, folderID: folderID)
                title = ""
                notes = ""
            }
        }
    }

    private var filters: some View {
        LifeOSCard(tokens: tokens) {
            SectionTitle("Filter", subtitle: "Search text and status", tokens: tokens)
            LifeTextField(title: "Search tasks", text: $searchText, tokens: tokens)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Button { statusFilter = nil } label: { ChoicePill(label: "All", selected: statusFilter == nil, tokens: tokens) }
                    ForEach(TaskStatus.allCases) { status in
                        Button { statusFilter = status } label: { ChoicePill(label: status.label, selected: statusFilter == status, tokens: tokens) }
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var taskList: some View {
        let tasks = filteredTasks
        return LifeOSCard(tokens: tokens) {
            SectionTitle("Task List", subtitle: "\(tasks.count) visible", tokens: tokens)
            if tasks.isEmpty {
                EmptyState(title: "No tasks", subtitle: "Create or adjust filters.", tokens: tokens)
            } else {
                ForEach(tasks) { task in
                    taskRow(task)
                }
            }
        }
    }

    private var filteredTasks: [LifeTask] {
        store.state.tasks
            .filter { statusFilter == nil || $0.status == statusFilter }
            .filter { SearchFilters.matchesTask($0, query: searchText) }
            .sorted {
                let left = $0.dueDate ?? Date.distantFuture
                let right = $1.dueDate ?? Date.distantFuture
                if left == right { return $0.createdAt > $1.createdAt }
                return left < right
            }
    }

    private func taskRow(_ task: LifeTask) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(tokens.primaryText)
                    Text(task.notes.isEmpty ? (task.dueDate?.lifeOSDayString ?? "No due date") : task.notes)
                        .font(.caption)
                        .foregroundStyle(tokens.secondaryText)
                        .lineLimit(2)
                }
                Spacer()
                Menu {
                    ForEach(TaskStatus.allCases) { status in
                        Button(status.label) { store.updateTaskStatus(task.id, status: status) }
                    }
                    Button("Delete", role: .destructive) { store.deleteTask(task.id) }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 34, height: 34)
                        .foregroundStyle(tokens.secondaryText)
                }
            }
            HStack {
                ChoicePill(label: task.priority.label, selected: true, tokens: tokens)
                ChoicePill(label: task.status.label, selected: task.status == .done, tokens: tokens)
            }
        }
        .padding(10)
        .background(tokens.elevatedSurface.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
