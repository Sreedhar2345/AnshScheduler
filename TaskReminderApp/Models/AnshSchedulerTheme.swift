import SwiftUI

/// Visual tokens for Ansh's Scheduler (#9CD5FF light, #355872 dark).
struct AnshSchedulerTheme: Equatable {
    let colorScheme: ColorScheme

    var screenBackground: Color {
        colorScheme == .dark ? Self.darkBackground : Self.lightBackground
    }

    var listRowTint: Color {
        colorScheme == .dark ? Color.white.opacity(0.14) : Color.white.opacity(0.55)
    }

    var primaryText: Color {
        colorScheme == .dark ? .white : Color(red: 0.08, green: 0.12, blue: 0.18)
    }

    var secondaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.78) : Color(red: 0.15, green: 0.22, blue: 0.32).opacity(0.85)
    }

    var taskIconBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.28) : Color.white.opacity(0.85)
    }

    var taskIconForeground: Color {
        colorScheme == .dark ? Self.darkBackground : Self.accentFill
    }

    var accentButtonBackground: Color {
        colorScheme == .dark ? .white : Self.accentFill
    }

    var accentButtonForeground: Color {
        colorScheme == .dark ? Self.darkBackground : .white
    }

    private static let lightBackground = Color(red: 156 / 255, green: 213 / 255, blue: 255 / 255)
    private static let darkBackground = Color(red: 53 / 255, green: 88 / 255, blue: 114 / 255)
    private static let accentFill = Color(red: 0.21, green: 0.34, blue: 0.45)
}

private struct AnshSchedulerThemeKey: EnvironmentKey {
    static let defaultValue = AnshSchedulerTheme(colorScheme: .light)
}

extension EnvironmentValues {
    var anshSchedulerTheme: AnshSchedulerTheme {
        get { self[AnshSchedulerThemeKey.self] }
        set { self[AnshSchedulerThemeKey.self] = newValue }
    }
}

struct AnshSchedulerThemeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.environment(\.anshSchedulerTheme, AnshSchedulerTheme(colorScheme: colorScheme))
    }
}

extension View {
    func anshSchedulerThemed() -> some View {
        modifier(AnshSchedulerThemeModifier())
    }
}
