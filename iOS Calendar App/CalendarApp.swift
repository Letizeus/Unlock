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
            }
        }
    }
    
    // Handles incoming .cal file URLs
    private func handleIncomingURL(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }  // Requests permission to access the file from system security
        defer { url.stopAccessingSecurityScopedResource() } // Ensures we release the security-scoped resource when we're done
        
        do {
            let data = try Data(contentsOf: url)
            let calendar = try AppData.shared.importCalendar(from: data)
            try AppData.shared.addToLibrary(calendar, type: .imported)
            
            // Redirects to library tab's imported section
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                let mainView = MainView(initialTab: .library)
                let hostingController = UIHostingController(rootView: mainView)
                window.rootViewController = hostingController
                
                // Ensures the library view's segment is set after the view is fully loaded
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(name: NSNotification.Name("SwitchToImportedSection"), object: nil)
                }
            }
        } catch {
            print("Error importing calendar: \(error)")
        }
    }
}
