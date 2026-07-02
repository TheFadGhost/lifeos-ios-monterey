import SwiftUI

@main
struct LifeOSApp: App {
    @StateObject private var store = LifeOSStore()

    var body: some Scene {
        WindowGroup {
            LifeOSRootShell()
                .environmentObject(store)
        }
    }
}

struct LifeOSRootShell: View {
    @EnvironmentObject private var store: LifeOSStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedRoute: LifeRoute = .dashboard

    var body: some View {
        let tokens = store.state.settings.theme.tokens(colorScheme: colorScheme)

        ZStack {
            LifeOSBackground(tokens: tokens)

            VStack(spacing: 0) {
                topBar(tokens: tokens)

                currentScreen(tokens: tokens)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                FloatingNavBar(routes: store.visibleBottomRoutes, selectedRoute: $selectedRoute, tokens: tokens)
            }
        }
        .preferredColorScheme(preferredScheme)
        .onChange(of: store.visibleBottomRoutes) { routes in
            if !routes.contains(selectedRoute), selectedRoute != .settings {
                selectedRoute = .dashboard
            }
        }
    }

    private var preferredScheme: ColorScheme? {
        switch store.state.settings.theme {
        case .system:
            return nil
        case .light, .sunrise, .sakura, .glass, .glassmorphism, .lofi, .coffee, .newspaper, .candy, .autumn, .snow, .memphis, .sepia:
            return .light
        default:
            return .dark
        }
    }

    @ViewBuilder
    private func currentScreen(tokens: LifeOSThemeTokens) -> some View {
        switch selectedRoute {
        case .dashboard:
            DashboardScreen(tokens: tokens) { selectedRoute = $0 }
        case .habits:
            HabitsScreen(tokens: tokens)
        case .tasks:
            TasksScreen(tokens: tokens)
        case .calendar:
            CalendarScreen(tokens: tokens)
        case .expenses:
            ExpensesScreen(tokens: tokens)
        case .fitness:
            FitnessScreen(tokens: tokens)
        case .journal:
            JournalScreen(tokens: tokens)
        case .notes:
            NotesScreen(tokens: tokens)
        case .settings:
            SettingsScreen(tokens: tokens)
        }
    }

    private func topBar(tokens: LifeOSThemeTokens) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedRoute.label)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(tokens.primaryText)
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    Text("\(LifeMetrics.greeting(forHour: Calendar.current.component(.hour, from: context.date))) · \(context.date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(tokens.secondaryText)
                }
            }

            Spacer()

            if store.state.settings.privacyMode {
                Image(systemName: "lock.fill")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(tokens.accent)
            }

            Button {
                selectedRoute = .settings
            } label: {
                Image(systemName: LifeRoute.settings.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 42, height: 42)
                    .foregroundStyle(tokens.primaryText)
                    .background(tokens.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(tokens.stroke, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }
}

extension View {
    func lifeOSScreenPadding() -> some View {
        modifier(LifeOSScreenPadding())
    }
}

private struct LifeOSScreenPadding: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 18)
            .padding(.bottom, 12)
    }
}
