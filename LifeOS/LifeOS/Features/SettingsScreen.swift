import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var store: LifeOSStore
    let tokens: LifeOSThemeTokens

    @State private var showingResetConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                themeCard
                privacyCard
                navCard
                exportCard
                aboutCard
            }
            .lifeOSScreenPadding()
        }
        .confirmationDialog("Reset local LifeOS data?", isPresented: $showingResetConfirm, titleVisibility: .visible) {
            Button("Reset", role: .destructive) { store.resetDemoData() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var themeCard: some View {
        LifeOSCard(tokens: tokens) {
            SectionTitle("Themes", subtitle: "Full UI presets ported from Android", tokens: tokens)
            Picker("Theme", selection: Binding(get: {
                store.state.settings.theme
            }, set: {
                store.setTheme($0)
            })) {
                ForEach(ThemePreference.allCases) { theme in
                    Text(theme.label).tag(theme)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var privacyCard: some View {
        LifeOSCard(tokens: tokens) {
            SectionTitle("Privacy & Widgets", subtitle: "Local controls only", tokens: tokens)
            Toggle("Privacy mode", isOn: Binding(get: {
                store.state.settings.privacyMode
            }, set: {
                store.setPrivacyMode($0)
            }))
            Toggle("Hide widget details", isOn: Binding(get: {
                store.state.settings.hideWidgetDetails
            }, set: {
                store.setHideWidgetDetails($0)
            }))
            Toggle("Widget enabled", isOn: Binding(get: {
                store.state.settings.widgetEnabled
            }, set: {
                store.setWidgetEnabled($0)
            }))
            Toggle("Confirm before export", isOn: Binding(get: {
                store.state.settings.confirmBeforeExport
            }, set: {
                store.setConfirmBeforeExport($0)
            }))
            LifeButton(title: "Allow Notifications", systemImage: "bell.badge.fill", tokens: tokens) {
                store.requestNotificationPermission()
            }
        }
        .foregroundStyle(tokens.primaryText)
    }

    private var navCard: some View {
        LifeOSCard(tokens: tokens) {
            SectionTitle("Customize Navigation", subtitle: "Dashboard stays protected", tokens: tokens)
            ForEach(LifeRoute.bottomRoutes) { route in
                HStack {
                    Label(route.label, systemImage: route.systemImage)
                        .foregroundStyle(tokens.primaryText)
                    Spacer()
                    Button {
                        store.moveRoute(route, direction: -1)
                    } label: {
                        Image(systemName: "chevron.up")
                    }
                    .disabled(route == .dashboard)
                    Button {
                        store.moveRoute(route, direction: 1)
                    } label: {
                        Image(systemName: "chevron.down")
                    }
                    .disabled(route == .dashboard)
                    Toggle("", isOn: Binding(get: {
                        !store.state.settings.hiddenRoutes.contains(route)
                    }, set: { visible in
                        store.setRoute(route, hidden: !visible)
                    }))
                    .labelsHidden()
                    .disabled(route == .dashboard)
                }
                .font(.callout)
            }
        }
    }

    private var exportCard: some View {
        LifeOSCard(tokens: tokens) {
            SectionTitle("Offline Export", subtitle: "JSON plus CSV tables", tokens: tokens)
            LifeButton(title: "Export Local Data", systemImage: "square.and.arrow.up.fill", tokens: tokens) {
                store.exportLocalArchive()
            }
            if let url = store.lastExportURL {
                Text(url.path)
                    .font(.caption)
                    .foregroundStyle(tokens.secondaryText)
                    .textSelection(.enabled)
            }
            if let error = store.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(tokens.danger)
            }
            Button(role: .destructive) {
                showingResetConfirm = true
            } label: {
                Label("Reset Local Data", systemImage: "trash")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .foregroundStyle(tokens.danger)
        }
    }

    private var aboutCard: some View {
        LifeOSCard(tokens: tokens) {
            SectionTitle("About", subtitle: "LifeOS iOS v1.00", tokens: tokens)
            Text("Native SwiftUI port. Offline-only. No accounts, cloud sync, analytics, remote config, or network features.")
                .font(.caption)
                .foregroundStyle(tokens.secondaryText)
            Text("Bundle: app.lifeos.ios · Currency: \(store.state.settings.currency)")
                .font(.caption)
                .foregroundStyle(tokens.secondaryText)
        }
    }
}
