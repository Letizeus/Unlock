import SwiftUI

// MARK: - OnboardingView

// Main container view that manages the onboarding flow
struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool // Tracks whether onboarding has been completed
    @State private var currentStep = OnboardingStep.welcome // Controls which step of onboarding is shown
    
    var body: some View {
        if currentStep == .welcome {
            WelcomeView(currentStep: $currentStep)
        } else {
            HomeView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .navigationBarBackButtonHidden(true)
        }
    }
}

// MARK: - WelcomeView

// Initial welcome screen that introduces the app's main features
struct WelcomeView: View {
    @Environment(\.editorTheme) private var theme
    @Binding var currentStep: OnboardingStep // Controls navigation to next step
    
    // Animation states
    @State private var showWelcome = false
    @State private var showUnlock = false
    @State private var showContent = false
    
    // Computed property for checking if on iPad
    private var onIPad: Bool {
        if (UIDevice.current.userInterfaceIdiom == .pad) {
            return true
        } else {
            return false
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 30) {
                // Animated headline section
                VStack(alignment: .leading, spacing: 8) {
                    // "Welcome to" text with slide-up animation
                    Text("Welcome to")
                        .bold()
                        .if(onIPad) { view in
                            view.font(.system(size: 60))
                        }
                        .font(.system(size: 36))
                        .minimumScaleFactor(0.75)
                        .lineLimit(1)
                        .offset(y: showWelcome ? 0 : 50)
                        .opacity(showWelcome ? 1 : 0)
                    
                    // "Unlock" text with scale and slide animation
                    Text("Unlock")
                        .bold()
                        .foregroundStyle(.main)
                        .if(onIPad) { view in
                            view.font(.system(size: 120))
                        }
                        .font(.system(size: 72))
                        .minimumScaleFactor(0.75)
                        .lineLimit(1)
                        .scaleEffect(showUnlock ? 1.2 : 0.8, anchor: .leading)
                        .offset(y: showUnlock ? 0 : 30)
                        .opacity(showUnlock ? 1 : 0)
                }
                
                // Content section with fade-in animation
                VStack(alignment: .leading, spacing: theme.spacing) {
                    // Feature items
                    featureItem(icon: Tab.calendar.icon,
                                title: "Your Journey",
                                description: "Complete calendars from other users by opening doors and embrace creative content.")
                    
                    featureItem(icon: Tab.editor.icon,
                                title: "Your Creativity",
                                description: "Create your own calenders in the editor and share them with the world.")
                    
                    featureItem(icon: "bell",
                                title: "Never Miss A Door",
                                description: "Receive notifications when a new door gets unlocked.")
                    
                    // Notification info
                    VStack(alignment: .center, spacing: theme.spacing) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.gray)
                        Text("Allow notifications in the next step to get notified when new doors get unlocked.")
                            .foregroundStyle(.gray)
                            .if(onIPad) { view in
                                view.font(.system(size: 15))
                            }
                            .font(.system(size: 13))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.75)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                }
                .offset(y: showContent ? 0 : 50)
                .opacity(showContent ? 1 : 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Next button
                Button(action: {
                    NotificationManager.shared.requestPermission()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        currentStep = .home
                    }
                }) {
                    Text("Next")
                        .bold()
                        .if(onIPad) { view in
                            view.font(.system(size: 20))
                        }
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.main)
                        .cornerRadius(theme.cornerRadius)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
            }
            
            .padding(50)
            .onAppear {
                animateEntrance()
            }
        }
    }
    
    // Creates an item with an icon, title, and description
    private func featureItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: onIPad ? 40 : 25) {
            Image(systemName: icon)
                .resizable()
            
                .if(onIPad) { view in
                    view.frame(width: 60, height: 60)
                }
            
                .frame(width: 50, height: 50)
            
                .aspectRatio(contentMode: .fit)
            
            VStack(alignment: .leading) {
                Text(title)
                    .bold()
                    .if(onIPad) { view in
                        view.font(.system(size: 20))
                    }
                    .font(.system(size: 17))
                    .minimumScaleFactor(0.75)
                    .lineLimit(1)
                Text(description)
                    .if(onIPad) { view in
                        view.font(.system(size: 20))
                    }
                    .font(.system(size: 17))
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    // Triggers the entrance animations in sequence with proper timing and spring effects
    private func animateEntrance() {
        // Welcome text animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
            showWelcome = true
        }
        // Unlock text animation with stronger spring effect
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.8)) {
            showUnlock = true
        }
        // Content animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.3)) {
            showContent = true
        }
    }
}

// Home view that provides initial setup options for the calendar
// Allows users to import existing calendars, use defaults, or create new ones
struct HomeView: View {
    @Environment(\.editorTheme) private var theme
    
    @Binding var hasCompletedOnboarding: Bool // Controls transition to main app
    
    @State private var showingImporter = false // Controls file importer presentation
    @State private var showingImportError = false // Controls error alert presentation
    @State private var importErrorMessage = "" // Stores current import error message
    
    @StateObject private var stateManager = CalendarStateManager.shared // Global calendar state
    
    @State private var selectedTab: Tab = .calendar // Selected tab in main view
    
    // Animation states
    @State private var appearAnimation = false
    @State private var optionsAnimation = [false, false, false]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Choose an option")
                    .font(theme.largeTitleFont).bold()
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 20)
                
                Text("to get started")
                    .font(theme.largeTitleFont).bold()
                    .foregroundStyle(.main)
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 20)
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .padding(.bottom, 40)
            
            // Options
            VStack(spacing: theme.spacing * 2) {
                // Import Calendar Option
                OptionButton(
                    icon: "square.and.arrow.down.fill",
                    title: "Import calendar",
                    subtitle: "Open an existing calendar file.",
                    isAnimated: optionsAnimation[0]
                ) {
                    showingImporter = true
                }
                
                // Default Calendar Option
                OptionButton(
                    icon: "calendar",
                    title: "Use empty calendar",
                    subtitle: "Load an empty calendar setup.",
                    isAnimated: optionsAnimation[1]
                ) {
                    useDefaultCalendar()
                }
                
                // Create New Calendar Option
                OptionButton(
                    icon: "pencil",
                    title: "Create your own",
                    subtitle: "Design a custom calendar from scratch.",
                    isAnimated: optionsAnimation[2]
                ) {
                    createNewCalendar()
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .background(Color(.systemBackground))
        .onAppear {
            animateEntrance()
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.holidayCalendar],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .alert("Import Error", isPresented: $showingImportError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importErrorMessage)
        }
    }
    
    // MARK: - Components
    
    /// Custom button design for options
    struct OptionButton: View {
        
        @Environment(\.editorTheme) private var theme
        
        let icon: String
        let title: String
        let subtitle: String
        let isAnimated: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack(spacing: 16) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: theme.cornerRadius)
                            .fill(.main)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: icon)
                            .font(theme.titleFont)
                            .foregroundColor(.white)
                    }
                    
                    // Text
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(theme.headlineFont)
                            .foregroundColor(.primary)
                        
                        Text(subtitle)
                            .font(theme.bodyFont)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(theme.bodyFont)
                        .foregroundColor(.secondary)
                }
                .padding(theme.padding)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(theme.cornerRadius)
            }
            .opacity(isAnimated ? 1 : 0)
            .offset(y: isAnimated ? 0 : 20)
        }
    }
    
    // Handles the entrance animations for the HomeView with sequenced timing
    private func animateEntrance() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            appearAnimation = true
        }
        
        // Animate options with sequential timing
        for index in 0..<3 {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2 + Double(index) * 0.1)) {
                optionsAnimation[index] = true
            }
        }
    }
    
    // Sets up and transitions to a default calendar
    private func useDefaultCalendar() {
        let defaultCalendar = HolidayCalendar.createDefault()
        stateManager.reset(with: defaultCalendar)
        completeOnboarding()
        
        transitionToMainView()
    }
    
    // Sets up and transitions to the calendar editor
    private func createNewCalendar() {
        let defaultCalendar = HolidayCalendar.createDefault()
        stateManager.reset(with: defaultCalendar)
        completeOnboarding()
        
        transitionToMainView(selectedTab: .editor)
    }
    
    // Handles the transition from onboarding to the main app interface
    private func transitionToMainView(selectedTab: Tab = .calendar) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let mainView = MainView(initialTab: selectedTab)
            
            window.rootViewController = UIHostingController(rootView: mainView)
        }
    }
    
    // Marks onboarding as complete and updates UserDefaults
    private func completeOnboarding() {
        hasCompletedOnboarding = true
    }
    
    // MARK: - Import Handling
    
    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                showImportError("No file selected")
                return
            }
            
            // Requests permission to access the file from system security
            guard url.startAccessingSecurityScopedResource() else {
                showImportError("Unable to access the selected file")
                return
            }
            
            // Ensures we release the security-scoped resource when we're done
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let data = try Data(contentsOf: url)
                try? FileManager.default.removeItem(at: AppData.shared.calendarURL)
                
                // Parses the calendar data using AppData's import
                // This handles both the calendar metadata and associated media files
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
                
                // Updates state and complete onboarding
                // Performed on main queue since it affects UI state
                DispatchQueue.main.async {
                    CalendarStateManager.shared.reset(with: resetCalendar)
                    completeOnboarding()
                }
                
                // Switches to MainView
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController = UIHostingController(rootView: MainView())
                }
                
            } catch {
                // Handles any errors during file reading or calendar import
                showImportError("Failed to import calendar: \(error.localizedDescription)")
            }
            
        case .failure(let error):
            // Handles file picker errors (e.g., user cancelled, no permission)
            showImportError("Error selecting file: \(error.localizedDescription)")
        }
    }
    
    // Shows an error alert with the specified message
    private func showImportError(_ message: String) {
        importErrorMessage = message
        showingImportError = true
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(true))
}
