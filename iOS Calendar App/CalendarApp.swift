import SwiftUI
import SwiftData

// Main entry point for the Holiday Calendar application
@main
struct CalendarApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false // Tracks whether the user has completed the onboarding process
    
    var body: some Scene {
        WindowGroup {
            // Shows either onboarding or main app based on onboarding completion state
            if hasCompletedOnboarding {
                MainView()
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
    }
}
