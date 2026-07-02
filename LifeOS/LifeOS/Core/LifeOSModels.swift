import Foundation

enum LifeRoute: String, CaseIterable, Codable, Identifiable {
    case dashboard
    case habits
    case tasks
    case calendar
    case expenses
    case fitness
    case journal
    case notes
    case settings

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dashboard: return "Home"
        case .habits: return "Habits"
        case .tasks: return "Tasks"
        case .calendar: return "Calendar"
        case .expenses: return "Money"
        case .fitness: return "Fitness"
        case .journal: return "Level Up"
        case .notes: return "Notes"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .habits: return "checkmark.circle.fill"
        case .tasks: return "checklist"
        case .calendar: return "calendar"
        case .expenses: return "creditcard.fill"
        case .fitness: return "figure.strengthtraining.traditional"
        case .journal: return "sparkles"
        case .notes: return "square.and.pencil"
        case .settings: return "gearshape.fill"
        }
    }

    static let bottomRoutes: [LifeRoute] = [.dashboard, .habits, .tasks, .calendar, .expenses, .fitness, .journal, .notes]
}

enum TaskPriority: String, CaseIterable, Codable, Identifiable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case urgent = "URGENT"

    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum TaskStatus: String, CaseIterable, Codable, Identifiable {
    case notStarted = "NOT_STARTED"
    case inProgress = "IN_PROGRESS"
    case done = "DONE"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .notStarted: return "Not started"
        case .inProgress: return "In progress"
        case .done: return "Done"
        }
    }
}

enum ReadingType: String, CaseIterable, Codable, Identifiable {
    case book = "BOOK"
    case article = "ARTICLE"
    case video = "VIDEO"
    case course = "COURSE"
    case other = "OTHER"

    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum ReadingStatus: String, CaseIterable, Codable, Identifiable {
    case saved = "SAVED"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    case archived = "ARCHIVED"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .saved: return "Saved"
        case .inProgress: return "In progress"
        case .completed: return "Completed"
        case .archived: return "Archived"
        }
    }
}

enum ReminderSourceType: String, CaseIterable, Codable, Identifiable {
    case task = "TASK"
    case habit = "HABIT"
    case event = "EVENT"
    case expense = "EXPENSE"
    case workout = "WORKOUT"
    case journal = "JOURNAL"
    case reading = "READING"

    var id: String { rawValue }
}

enum ThemePreference: String, CaseIterable, Codable, Identifiable {
    case system = "SYSTEM"
    case light = "LIGHT"
    case dark = "DARK"
    case midnight = "MIDNIGHT"
    case forest = "FOREST"
    case sunrise = "SUNRISE"
    case samurai = "SAMURAI"
    case pixel = "PIXEL"
    case sakura = "SAKURA"
    case glass = "GLASS"
    case neumorphic = "NEUMORPHIC"
    case glassmorphism = "GLASSMORPHISM"
    case rainy = "RAINY"
    case lofi = "LOFI"
    case anime = "ANIME"
    case terminal = "TERMINAL"
    case vaporwave = "VAPORWAVE"
    case coffee = "COFFEE"
    case ocean = "OCEAN"
    case newspaper = "NEWSPAPER"
    case candy = "CANDY"
    case galaxy = "GALAXY"
    case autumn = "AUTUMN"
    case snow = "SNOW"
    case memphis = "MEMPHIS"
    case neonCity = "NEON_CITY"
    case sepia = "SEPIA"
    case amoled = "AMOLED"
    case stainedGlass = "STAINED_GLASS"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        case .midnight: return "Midnight"
        case .forest: return "Forest"
        case .sunrise: return "Sunrise"
        case .samurai: return "Samurai"
        case .pixel: return "8-bit Console"
        case .sakura: return "Sakura"
        case .glass: return "Adaptive Glass"
        case .neumorphic: return "Dark Neumorphism"
        case .glassmorphism: return "Glassmorphism"
        case .rainy: return "Rainy Focus"
        case .lofi: return "Lofi Girl"
        case .anime: return "Anime Cyberpunk"
        case .terminal: return "Terminal"
        case .vaporwave: return "Vaporwave"
        case .coffee: return "Coffee Shop"
        case .ocean: return "Deep Ocean"
        case .newspaper: return "Newspaper"
        case .candy: return "Candy"
        case .galaxy: return "Galaxy"
        case .autumn: return "Autumn"
        case .snow: return "Arctic Snow"
        case .memphis: return "90s Memphis"
        case .neonCity: return "Neon City"
        case .sepia: return "Burnt Vintage"
        case .amoled: return "AMOLED Black"
        case .stainedGlass: return "Stained Glass"
        }
    }
}

struct LifeSettings: Codable, Equatable {
    var currency: String = "GBP"
    var theme: ThemePreference = .system
    var privacyMode: Bool = false
    var hideWidgetDetails: Bool = false
    var confirmBeforeExport: Bool = true
    var widgetEnabled: Bool = true
    var navOrder: [LifeRoute] = LifeRoute.bottomRoutes
    var hiddenRoutes: Set<LifeRoute> = []
}

struct Reminder: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var sourceType: ReminderSourceType
    var sourceID: UUID
    var title: String
    var message: String = ""
    var scheduledAt: Date
    var repeatRule: String?
    var enabled: Bool = true
    var createdAt: Date = Date()
}

struct Habit: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var description: String = ""
    var icon: String = "check"
    var sortOrder: Int = 0
    var isActive: Bool = true
    var createdAt: Date = Date()
}

struct HabitLog: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var habitID: UUID
    var date: Date
    var completedAt: Date = Date()
}

struct TaskFolder: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var color: String
    var sortOrder: Int = 0
}

struct Tag: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var color: String
}

struct LifeTask: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var folderID: UUID?
    var title: String
    var notes: String = ""
    var dueDate: Date?
    var priority: TaskPriority = .medium
    var status: TaskStatus = .notStarted
    var tagIDs: [UUID] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var completedAt: Date?
}

struct CalendarEvent: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var notes: String = ""
    var date: Date
    var startTimeMinutes: Int?
    var endTimeMinutes: Int?
    var category: String = "General"
    var createdAt: Date = Date()
}

struct ExpenseCategory: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var color: String
    var icon: String
    var sortOrder: Int = 0
}

struct Expense: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var amountMinor: Int
    var currency: String = "GBP"
    var categoryID: UUID?
    var date: Date
    var notes: String = ""
    var createdAt: Date = Date()
}

struct MuscleGroup: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var icon: String
    var sortOrder: Int = 0
}

struct Exercise: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var muscleGroupID: UUID
    var name: String
    var instructions: String = ""
    var builtInIcon: String = "fitness"
    var localImagePath: String?
    var createdAt: Date = Date()
}

struct WorkoutSession: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var title: String = "Workout"
    var notes: String = ""
    var startedAt: Date = Date()
    var endedAt: Date?
}

struct WorkoutSet: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var sessionID: UUID
    var exerciseID: UUID
    var setNumber: Int
    var reps: Int
    var weight: Double
    var weightUnit: String = "kg"
    var notes: String = ""
}

struct JournalEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var prompt: String = "What went well today?"
    var body: String = ""
    var moodRating: Int?
    var moodEmoji: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

struct ReadingItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var type: ReadingType = .other
    var notes: String = ""
    var status: ReadingStatus = .saved
    var sourceLabel: String = ""
    var createdAt: Date = Date()
    var completedAt: Date?
}

struct NoteFolder: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var color: String = "#888888"
    var icon: String = "folder"
    var sortOrder: Int = 0
    var createdAt: Date = Date()
}

struct NoteTag: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var color: String = "#888888"
}

struct LifeNote: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var folderID: UUID?
    var title: String = ""
    var body: String = ""
    var isPinned: Bool = false
    var isDaily: Bool = false
    var dailyDate: Date?
    var tagIDs: [UUID] = []
    var linkedNoteIDs: [UUID] = []
    var wordCount: Int = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var deletedAt: Date?
}

struct Attachment: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var sourceType: ReminderSourceType
    var sourceID: UUID
    var localPath: String
    var mimeType: String
    var label: String
    var createdAt: Date = Date()
}

struct LifeOSState: Codable, Equatable {
    var settings: LifeSettings = LifeSettings()
    var reminders: [Reminder] = []
    var attachments: [Attachment] = []
    var habits: [Habit] = []
    var habitLogs: [HabitLog] = []
    var taskFolders: [TaskFolder] = []
    var tags: [Tag] = []
    var tasks: [LifeTask] = []
    var events: [CalendarEvent] = []
    var expenseCategories: [ExpenseCategory] = []
    var expenses: [Expense] = []
    var muscleGroups: [MuscleGroup] = []
    var exercises: [Exercise] = []
    var workoutSessions: [WorkoutSession] = []
    var workoutSets: [WorkoutSet] = []
    var journalEntries: [JournalEntry] = []
    var readingItems: [ReadingItem] = []
    var noteFolders: [NoteFolder] = []
    var noteTags: [NoteTag] = []
    var notes: [LifeNote] = []

    static func seeded(now: Date = Date(), calendar: Calendar = .current) -> LifeOSState {
        let today = calendar.startOfDay(for: now)
        var state = LifeOSState()
        state.settings = LifeSettings()

        state.habits = ["Drink water", "Read", "Meditate", "Exercise"].enumerated().map { index, title in
            Habit(title: title, sortOrder: index, createdAt: now)
        }

        state.taskFolders = [
            TaskFolder(name: "Work", color: "#3E5F8A", sortOrder: 0),
            TaskFolder(name: "Personal", color: "#2F5F4F", sortOrder: 1),
            TaskFolder(name: "Studies", color: "#8A5F3E", sortOrder: 2)
        ]

        state.expenseCategories = [
            ExpenseCategory(name: "Rent", color: "#8A5F3E", icon: "house", sortOrder: 0),
            ExpenseCategory(name: "Food", color: "#A35F3B", icon: "fork.knife", sortOrder: 1),
            ExpenseCategory(name: "Transport", color: "#3E5F8A", icon: "bus", sortOrder: 2),
            ExpenseCategory(name: "Health", color: "#7A4E7A", icon: "cross.case", sortOrder: 3),
            ExpenseCategory(name: "Fitness", color: "#2F5F4F", icon: "figure.strengthtraining.traditional", sortOrder: 4),
            ExpenseCategory(name: "Subscriptions", color: "#6F6A5A", icon: "repeat", sortOrder: 5),
            ExpenseCategory(name: "Other", color: "#555555", icon: "ellipsis", sortOrder: 6)
        ]

        state.muscleGroups = [
            MuscleGroup(name: "Chest", icon: "chest", sortOrder: 0),
            MuscleGroup(name: "Back", icon: "back", sortOrder: 1),
            MuscleGroup(name: "Legs", icon: "legs", sortOrder: 2),
            MuscleGroup(name: "Shoulders", icon: "shoulders", sortOrder: 3),
            MuscleGroup(name: "Arms", icon: "arms", sortOrder: 4),
            MuscleGroup(name: "Core", icon: "core", sortOrder: 5)
        ]

        func groupID(_ name: String) -> UUID {
            state.muscleGroups.first { $0.name == name }?.id ?? state.muscleGroups[0].id
        }

        state.exercises = [
            Exercise(muscleGroupID: groupID("Chest"), name: "Push-up", instructions: "Bodyweight press for chest and triceps.", createdAt: now),
            Exercise(muscleGroupID: groupID("Chest"), name: "Bench Press", instructions: "Horizontal press with controlled tempo.", createdAt: now),
            Exercise(muscleGroupID: groupID("Back"), name: "Row", instructions: "Pull elbows back and squeeze shoulder blades.", createdAt: now),
            Exercise(muscleGroupID: groupID("Back"), name: "Lat Pulldown", instructions: "Vertical pull for lats and upper back.", createdAt: now),
            Exercise(muscleGroupID: groupID("Legs"), name: "Squat", instructions: "Lower with control and drive through the floor.", createdAt: now),
            Exercise(muscleGroupID: groupID("Legs"), name: "Romanian Deadlift", instructions: "Hinge at the hips with a neutral spine.", createdAt: now),
            Exercise(muscleGroupID: groupID("Shoulders"), name: "Shoulder Press", instructions: "Vertical press without over-arching.", createdAt: now),
            Exercise(muscleGroupID: groupID("Arms"), name: "Bicep Curl", instructions: "Curl with elbows pinned and controlled descent.", createdAt: now),
            Exercise(muscleGroupID: groupID("Core"), name: "Plank", instructions: "Brace core and hold a straight line.", createdAt: now)
        ]

        state.noteFolders = [
            NoteFolder(name: "Inbox", color: "#3E5F8A", icon: "tray", sortOrder: 0, createdAt: now),
            NoteFolder(name: "Daily", color: "#2F5F4F", icon: "calendar", sortOrder: 1, createdAt: now)
        ]

        state.journalEntries = [
            JournalEntry(date: today, body: "", createdAt: now, updatedAt: now)
        ]

        return state
    }
}

extension DateFormatter {
    static let lifeOSDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

extension Date {
    var lifeOSDayString: String {
        DateFormatter.lifeOSDay.string(from: Calendar.current.startOfDay(for: self))
    }

    func addingDays(_ days: Int, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: self)) ?? self
    }

    func addingWeeks(_ weeks: Int, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: weeks * 7, to: calendar.startOfDay(for: self)) ?? self
    }

    func addingMonths(_ months: Int, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .month, value: months, to: calendar.startOfDay(for: self)) ?? self
    }

    func isSameDay(as other: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(self, inSameDayAs: other)
    }
}

extension String {
    var trimmedNonEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
