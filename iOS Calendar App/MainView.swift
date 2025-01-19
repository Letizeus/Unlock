import SwiftUI

struct MainView: View {
    
    // MARK: - Properties
    
    @Environment(\.colorScheme) var colorScheme // Detects system color scheme changes
    @StateObject private var themeManager = ThemeManager.shared // Manages theme updates for the entire app
    @StateObject private var stateManager = CalendarStateManager.shared // Global calendar state manager - source of truth for door states
    
    @State private var selectedTab = Tab.calendar
    
    // MARK: - Initialization
    
    init(initialTab: Tab = .calendar) {
        _selectedTab = State(initialValue: initialTab)
    }
    
    // MARK: - View Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            calendarTab
            mapTab
            editorTab
            libraryTab
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToEditorTab"))) { _ in
            selectedTab = .editor
        }
        // Updates theme when colorScheme changes
        .onAppear {
            themeManager.updateForColorScheme(colorScheme)
            UITabBar.appearance().scrollEdgeAppearance = UITabBarAppearance()
        }
        .onChange(of: colorScheme) { _, newValue in
            themeManager.updateForColorScheme(newValue)
        }
        // Provides the theme through the environment
        .environment(\.calendarTheme, themeManager.calendarTheme)
        .environment(\.editorTheme, themeManager.editorTheme)
        .environment(\.mapTheme, themeManager.mapTheme)
    }
    
    // MARK: - Tab Views
    
    private var calendarTab: some View {
        TabViewCalendar(calendar: stateManager.calendar) // Uses the currentCalendar state
            .tabItem {
                Label(Tab.calendar.title, systemImage: Tab.calendar.icon)
            }
            .tag(Tab.calendar)
    }
    
    private var mapTab: some View {
        TabViewMap(calendar: stateManager.calendar)
            .tabItem {
                Label(Tab.map.title, systemImage: Tab.map.icon)
            }
            .tag(Tab.map)
    }
    
    private var editorTab: some View {
        TabViewEditor(onSaveCalendar: { newCalendar in
            stateManager.calendar = newCalendar // Updates the currentCalendar state
            selectedTab = .calendar // Switches to calendar tab after saving
        })
        .tabItem {
            Label(Tab.editor.title, systemImage: Tab.editor.icon)
        }
        .tag(Tab.editor)
    }
    
    private var libraryTab: some View {
        TabViewLibrary()
            .tabItem {
                Label(Tab.library.title, systemImage: Tab.library.icon)
            }
            .tag(Tab.library)
    }
}

// MARK: - Preview

#Preview {
    MainView()
}
