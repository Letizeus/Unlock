import SwiftUI
import SwiftData

@main
struct CalendarApp: App {
    
    @StateObject private var themeManager = ThemeManager() // Manages theme-related state across the app
    @StateObject private var stateManager = CalendarStateManager.shared // Manages global calendar state
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                // Injects theme values into the environment for child views to access
                .environment(\.calendarTheme, themeManager.calendarTheme)
                .environment(\.editorTheme, themeManager.editorTheme)
                .environment(\.mapTheme, themeManager.mapTheme)
        }
        .modelContainer(sharedModelContainer)
    }
}
