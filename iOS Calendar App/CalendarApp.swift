import SwiftUI
import SwiftData

// Main entry point for the Holiday Calendar application
@main
struct CalendarApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            LaunchScreenView()
        }
    }
}

// App delegate to handle application-level events
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}

// Scene delegate to handle scene-level events including URL handling
class SceneDelegate: NSObject, UIWindowSceneDelegate {
    // Handles URLs passed on launch
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let urls = connectionOptions.urlContexts.map { $0.url }
        if !urls.isEmpty {
            handleIncomingURLs(urls)
        }
    }
    // Handles URLs when app is running
    func scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
        let urls = urlContexts.map { $0.url }
        handleIncomingURLs(urls)
    }
    
    // Handles multiple incoming .cal file URLs
    private func handleIncomingURLs(_ urls: [URL]) {
        for url in urls {
            guard url.startAccessingSecurityScopedResource() else { continue }  // Requests permission to access the file from system security
            defer { url.stopAccessingSecurityScopedResource() } // Ensures we release the security-scoped resource when we're done
            
            do {
                let data = try Data(contentsOf: url)
                let calendar = try AppData.shared.importCalendar(from: data)
                try AppData.shared.addToLibrary(calendar, type: .imported)
            } catch {
                print("Error importing calendar: \(error)")
            }
        }
        
        // Redirects to library tab's imported section after processing all URLs
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
    }
}

// MARK: - iPad support view extension
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
