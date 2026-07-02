import SwiftUI

struct LifeOSBackground: View {
    let tokens: LifeOSThemeTokens

    var body: some View {
        tokens.backgroundGradient.ignoresSafeArea()
    }
}

struct LifeOSCard<Content: View>: View {
    let tokens: LifeOSThemeTokens
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tokens.surface)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(tokens.stroke, lineWidth: 1)
        )
    }
}

struct SectionTitle: View {
    let title: String
    let subtitle: String?
    let tokens: LifeOSThemeTokens

    init(_ title: String, subtitle: String? = nil, tokens: LifeOSThemeTokens) {
        self.title = title
        self.subtitle = subtitle
        self.tokens = tokens
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.headline)
                .foregroundStyle(tokens.primaryText)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(tokens.secondaryText)
            }
        }
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let subtitle: String
    let progress: Double
    let tokens: LifeOSThemeTokens

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(tokens.secondaryText)
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tokens.primaryText)
            ProgressView(value: progress)
                .tint(tokens.accent)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(tokens.secondaryText)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tokens.elevatedSurface.opacity(0.68))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct ChoicePill: View {
    let label: String
    let selected: Bool
    let tokens: LifeOSThemeTokens

    var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(selected ? tokens.backgroundTop : tokens.primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selected ? tokens.accent : tokens.elevatedSurface.opacity(0.70))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(tokens.stroke, lineWidth: selected ? 0 : 1))
    }
}

struct LifeTextField: View {
    let title: String
    @Binding var text: String
    let tokens: LifeOSThemeTokens
    var axis: Axis = .horizontal

    var body: some View {
        TextField(title, text: $text, axis: axis)
            .textFieldStyle(.plain)
            .padding(12)
            .foregroundStyle(tokens.primaryText)
            .background(tokens.elevatedSurface.opacity(0.78))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(tokens.stroke, lineWidth: 1)
            )
    }
}

struct LifeButton: View {
    let title: String
    let systemImage: String
    let tokens: LifeOSThemeTokens
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.callout.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .foregroundStyle(tokens.backgroundTop)
        .background(tokens.accent)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct FloatingNavBar: View {
    let routes: [LifeRoute]
    @Binding var selectedRoute: LifeRoute
    let tokens: LifeOSThemeTokens

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(routes) { route in
                    Button {
                        selectedRoute = route
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: route.systemImage)
                                .font(.system(size: 18, weight: .semibold))
                            Text(route.label)
                                .font(.caption2.weight(.semibold))
                                .lineLimit(1)
                        }
                        .frame(width: 70, height: 54)
                        .foregroundStyle(selectedRoute == route ? tokens.backgroundTop : tokens.secondaryText)
                        .background(
                            selectedRoute == route
                                ? tokens.accent.opacity(0.92)
                                : tokens.elevatedSurface.opacity(0.12)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
        }
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(tokens.surface.opacity(0.46))
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(tokens.stroke, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.16), radius: 18, x: 0, y: 10)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
}

struct EmptyState: View {
    let title: String
    let subtitle: String
    let tokens: LifeOSThemeTokens

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tokens.primaryText)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(tokens.secondaryText)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tokens.elevatedSurface.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct RouteButton: View {
    let route: LifeRoute
    let tokens: LifeOSThemeTokens
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: route.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 28, height: 28)
                    .background(tokens.accentMuted)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                Text(route.label)
                    .font(.callout.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tokens.secondaryText)
            }
            .foregroundStyle(tokens.primaryText)
            .padding(12)
            .background(tokens.elevatedSurface.opacity(0.64))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
