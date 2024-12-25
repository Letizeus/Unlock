import SwiftUI

struct MainView: View {
    
    // MARK: - Properties
    
    @StateObject private var themeManager = ThemeManager()
    @Environment(\.colorScheme) var colorScheme // Reads whether the user's system is in light or dark mode
    
    @State private var selectedTab = Tab.calendar
    @State private var currentCalendar: HolidayCalendar = HolidayCalendar.createDefault()
    
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
        }
        .onChange(of: colorScheme) { _, newValue in
            themeManager.updateForColorScheme(newValue)
        }
        // Provide the theme through the environment
        .environment(\.calendarTheme, themeManager.calendarTheme)
        .environment(\.editorTheme, themeManager.editorTheme)
    }
    
    // MARK: - Tab Views
    
    private var calendarTab: some View {
        TabViewCalendar(calendar: currentCalendar) // Use the currentCalendar state
            .tabItem {
                Label(Tab.calendar.title, systemImage: Tab.calendar.icon)
            }
            .tag(Tab.calendar)
    }
    
    private var mapTab: some View {
        TabViewMap()
            .tabItem {
                Label(Tab.map.title, systemImage: Tab.map.icon)
            }
            .tag(Tab.map)
    }
    
    private var editorTab: some View {
        TabViewEditor(onSaveCalendar: { newCalendar in
            currentCalendar = newCalendar // Update the currentCalendar state
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
