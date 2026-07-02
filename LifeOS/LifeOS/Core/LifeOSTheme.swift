import Foundation
import SwiftUI

struct LifeOSThemeTokens {
    var backgroundTop: Color
    var backgroundBottom: Color
    var surface: Color
    var elevatedSurface: Color
    var primaryText: Color
    var secondaryText: Color
    var accent: Color
    var accentMuted: Color
    var stroke: Color
    var warning: Color = Color(hex: "#FFD34D")
    var danger: Color = Color(hex: "#FF6B6B")

    var backgroundGradient: LinearGradient {
        LinearGradient(colors: [backgroundTop, backgroundBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

extension ThemePreference {
    func tokens(colorScheme: ColorScheme) -> LifeOSThemeTokens {
        switch self {
        case .system:
            return (colorScheme == .dark ? ThemePreference.dark : ThemePreference.light).tokens(colorScheme: colorScheme)
        case .light:
            return LifeOSThemeTokens(
                backgroundTop: Color(hex: "#F7F5EF"),
                backgroundBottom: Color(hex: "#E9EEF6"),
                surface: Color.white.opacity(0.86),
                elevatedSurface: Color(hex: "#FFFFFF"),
                primaryText: Color(hex: "#161617"),
                secondaryText: Color(hex: "#5A5F69"),
                accent: Color(hex: "#2F80ED"),
                accentMuted: Color(hex: "#DCEBFF"),
                stroke: Color.black.opacity(0.10)
            )
        case .dark:
            return LifeOSThemeTokens(
                backgroundTop: Color(hex: "#111317"),
                backgroundBottom: Color(hex: "#1E232B"),
                surface: Color(hex: "#1B2028").opacity(0.92),
                elevatedSurface: Color(hex: "#232A33"),
                primaryText: Color(hex: "#F4F5F7"),
                secondaryText: Color(hex: "#B8C0CC"),
                accent: Color(hex: "#7DB1FF"),
                accentMuted: Color(hex: "#20344F"),
                stroke: Color.white.opacity(0.12)
            )
        case .midnight:
            return darkTokens(top: "#080B16", bottom: "#141B2F", accent: "#8EA7FF")
        case .forest:
            return darkTokens(top: "#0F1A15", bottom: "#1D3328", accent: "#83D6A3")
        case .sunrise:
            return lightTokens(top: "#FFF1D8", bottom: "#FCE1DE", accent: "#F26A3D")
        case .samurai:
            return darkTokens(top: "#160F12", bottom: "#302226", accent: "#FF5A5F")
        case .pixel:
            return darkTokens(top: "#070707", bottom: "#171717", accent: "#57FF7A")
        case .sakura:
            return lightTokens(top: "#FFF2F7", bottom: "#F7DDE7", accent: "#D94B8A")
        case .glass:
            return lightTokens(top: "#ECF8FF", bottom: "#EEF2FF", accent: "#3D83F6")
        case .neumorphic:
            return darkTokens(top: "#191A1F", bottom: "#24252C", accent: "#FF9F43")
        case .glassmorphism:
            return lightTokens(top: "#FBEAFF", bottom: "#DFFDF5", accent: "#9B5CFF")
        case .rainy:
            return darkTokens(top: "#111923", bottom: "#1A2632", accent: "#84B7D8")
        case .lofi:
            return lightTokens(top: "#F7E7C6", bottom: "#DEC89A", accent: "#B76E30")
        case .anime:
            return darkTokens(top: "#080818", bottom: "#21113B", accent: "#39F0FF")
        case .terminal:
            return darkTokens(top: "#020403", bottom: "#07120A", accent: "#30FF6A")
        case .vaporwave:
            return darkTokens(top: "#20103B", bottom: "#4D1B52", accent: "#FF71CE")
        case .coffee:
            return lightTokens(top: "#EFE3D2", bottom: "#C9AC8B", accent: "#7A4F2C")
        case .ocean:
            return darkTokens(top: "#061E2B", bottom: "#0F3A4A", accent: "#4DD7F8")
        case .newspaper:
            return lightTokens(top: "#F5F1E8", bottom: "#E2DDD0", accent: "#222222")
        case .candy:
            return lightTokens(top: "#FFF0F8", bottom: "#E6F7FF", accent: "#FF5DA2")
        case .galaxy:
            return darkTokens(top: "#070415", bottom: "#24164D", accent: "#B185FF")
        case .autumn:
            return lightTokens(top: "#FFE9CC", bottom: "#E4B67D", accent: "#B4532A")
        case .snow:
            return lightTokens(top: "#F8FCFF", bottom: "#DFECF6", accent: "#3B82F6")
        case .memphis:
            return lightTokens(top: "#FFF7DE", bottom: "#F4E6FF", accent: "#F97316")
        case .neonCity:
            return darkTokens(top: "#050712", bottom: "#111A33", accent: "#F72585")
        case .sepia:
            return lightTokens(top: "#EFE0C6", bottom: "#C7A87C", accent: "#7C4A20")
        case .amoled:
            return darkTokens(top: "#000000", bottom: "#000000", accent: "#00E0FF")
        case .stainedGlass:
            return darkTokens(top: "#101025", bottom: "#2A1641", accent: "#F5C542")
        }
    }

    private func darkTokens(top: String, bottom: String, accent: String) -> LifeOSThemeTokens {
        LifeOSThemeTokens(
            backgroundTop: Color(hex: top),
            backgroundBottom: Color(hex: bottom),
            surface: Color(hex: "#161B22").opacity(0.90),
            elevatedSurface: Color(hex: "#202833"),
            primaryText: Color(hex: "#F7F8FA"),
            secondaryText: Color(hex: "#B9C1CC"),
            accent: Color(hex: accent),
            accentMuted: Color(hex: accent).opacity(0.22),
            stroke: Color.white.opacity(0.14)
        )
    }

    private func lightTokens(top: String, bottom: String, accent: String) -> LifeOSThemeTokens {
        LifeOSThemeTokens(
            backgroundTop: Color(hex: top),
            backgroundBottom: Color(hex: bottom),
            surface: Color.white.opacity(0.78),
            elevatedSurface: Color.white.opacity(0.94),
            primaryText: Color(hex: "#161617"),
            secondaryText: Color(hex: "#5B616C"),
            accent: Color(hex: accent),
            accentMuted: Color(hex: accent).opacity(0.16),
            stroke: Color.black.opacity(0.10)
        )
    }
}

extension Color {
    init(hex: String) {
        let raw = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: raw).scanHexInt64(&value)

        let red: UInt64
        let green: UInt64
        let blue: UInt64
        switch raw.count {
        case 3:
            red = ((value >> 8) & 0xF) * 17
            green = ((value >> 4) & 0xF) * 17
            blue = (value & 0xF) * 17
        default:
            red = (value >> 16) & 0xFF
            green = (value >> 8) & 0xFF
            blue = value & 0xFF
        }

        self.init(.sRGB, red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255, opacity: 1)
    }
}
