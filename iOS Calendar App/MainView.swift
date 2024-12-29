import SwiftUI

struct MainView: View {
    
    // MARK: - Properties
    
    @Environment(\.colorScheme) var colorScheme // Detects system color scheme changes
    @StateObject private var themeManager = ThemeManager() // Manages theme updates for the entire app
    @StateObject private var stateManager = CalendarStateManager.shared // Global calendar state manager - source of truth for door states
    
    @State private var selectedTab = Tab.calendar
    
    // MARK: - View Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            calendarTab
            mapTab
            editorTab
        }
        // Update theme when colorScheme changes
        .onAppear {
            themeManager.updateForColorScheme(colorScheme)
            UITabBarAppearance().configureWithOpaqueBackground()
            UITabBar.appearance().scrollEdgeAppearance = UITabBarAppearance()
        }
        .onChange(of: colorScheme) { _, newValue in
            themeManager.updateForColorScheme(newValue)
        }
        // Provide the theme through the environment
        .environment(\.calendarTheme, themeManager.calendarTheme)
        .environment(\.editorTheme, themeManager.editorTheme)
        .environment(\.mapTheme, themeManager.mapTheme)
    }
    
    // MARK: - Tab Views
    
    private var calendarTab: some View {
        TabViewCalendar(calendar: stateManager.calendar) // Use the currentCalendar state
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
            stateManager.calendar = newCalendar // Update the currentCalendar state
            selectedTab = .calendar // Switch to calendar tab after saving
        })
        .tabItem {
            Label(Tab.editor.title, systemImage: Tab.editor.icon)
        }
        .tag(Tab.editor)
    }
}

// MARK: - Preview

#Preview {
    MainView()
}
