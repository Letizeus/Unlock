import SwiftUI
import Foundation

// Manages theme state and updates across the entire application
// Uses ObservableObject to allow views to react to theme changes
class ThemeManager: ObservableObject {
    // private(set) allows reading from outside but only writing from within this class
    @Published private(set) var calendarTheme: CalendarTheme
    @Published private(set) var editorTheme: EditorTheme
    
    // Allows for custom themes to be set at initialization if needed
    init(
        calendarTheme : CalendarTheme = .default,
        editorTheme: EditorTheme = .default
    ) {
        self.calendarTheme = calendarTheme
        self.editorTheme = editorTheme
    }
    
    // Update theme based on color scheme changes
    func updateForColorScheme(_ colorScheme: ColorScheme) {
        calendarTheme = colorScheme == .dark ? .darkMode : .lightMode
    }
    
    func updateCalendarTheme(_ theme: CalendarTheme) {
        calendarTheme = theme
    }
    
    func updateEditorTheme(_ theme: EditorTheme) {
        editorTheme = theme
    }
}

// MARK: - Environment Values Extension

// Allows theme to be accessed through SwiftUI environment
private struct CalendarThemeKey: EnvironmentKey {
    static let defaultValue = CalendarTheme.default
}

private struct EditorThemeKey: EnvironmentKey {
    static let defaultValue = EditorTheme.default
}

// This allows views to access themes through the environment
extension EnvironmentValues {
    // Usage: @Environment(\.calendarTheme) private var theme
    var calendarTheme: CalendarTheme {
        get { self[CalendarThemeKey.self] }
        set { self[CalendarThemeKey.self] = newValue }
    }    
    // Usage: @Environment(\.editorTheme) private var theme
    var editorTheme: EditorTheme {
        get { self[EditorThemeKey.self] }
        set { self[EditorThemeKey.self] = newValue }
    }
}
