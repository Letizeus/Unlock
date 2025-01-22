import SwiftUI
import SwiftData

// Main entry point for the Holiday Calendar application
@main
struct CalendarApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false // Tracks whether the user has completed the onboarding process
    @State private var openURL: URL? = nil // Tracks incoming file URL
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainView()
                    .onOpenURL { url in
                        handleIncomingURL(url)
                    }
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .onOpenURL { url in
                        openURL = url
                    }
            }
        }
    }
    
    // Handles incoming .cal file URLs
    private func handleIncomingURL(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let data = try Data(contentsOf: url)
            let calendar = try AppData.shared.importCalendar(from: data)
            
            // Creates a fresh calendar with reset states
            let resetCalendar = HolidayCalendar(
                title: calendar.title,
                startDate: calendar.startDate,
                endDate: calendar.endDate,
                doors: calendar.doors.map { door in
                    CalendarDoor(
                        number: door.number,
                        unlockDate: door.unlockDate,
                        isUnlocked: Calendar.current.startOfDay(for: Date()) >= Calendar.current.startOfDay(for: door.unlockDate),
                        content: door.content,
                        hasBeenOpened: door.hasBeenOpened
                    )
                },
                gridColumns: calendar.gridColumns,
                backgroundImageData: calendar.backgroundImageData,
                backgroundColor: calendar.backgroundColor,
                doorColor: calendar.doorColor
            )
            CalendarStateManager.shared.reset(with: resetCalendar) // Updates the calendar state
            try AppData.shared.addToLibrary(resetCalendar, type: .imported) // Adds the calendar to the library
            // Force switches to calendar tab
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController = UIHostingController(rootView: MainView(initialTab: .calendar))
            }
            
        } catch {
            print("Error handling incoming URL: \(error)")
        }
    }
}
