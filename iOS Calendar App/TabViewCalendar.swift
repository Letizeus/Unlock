import SwiftUI

struct TabViewCalendar: View {
    
    @Environment(\.calendarTheme) private var theme // Access the calendar theme from the environment
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Properties
    
    let calendar: HolidayCalendar // The calendar data model containing all doors and their content
    @State private var isAnyDoorOpening = false // Only one door at once
    @State private var countdown = CountdownInfo() // Current countdown information (days, hours, minutes)
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()// Timer that updates the countdown every second
    
    // MARK: - Initialization
    
    init(calendar: HolidayCalendar) {
        self.calendar = calendar
    }
    
    // MARK: - View Body
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in // GeometryReader provides access to the parent view's dimensions
                ZStack {
                    backgroundLayer
                        .edgesIgnoringSafeArea(.all)
                    
                    // Main content layout including title, countdown and calendar grid
                    VStack(spacing: 0) {
                        Text(calendar.title)
                            .font(theme.titleFont)
                            .bold()
                            .foregroundStyle(theme.text)
                            .padding(.top, theme.padding.top)
                            .padding(.bottom, theme.padding.bottom)
                        
                        if areAllDoorsUnlocked() {
                            completionView
                                .padding(.bottom, theme.padding.bottom)
                        } else {
                            countdownView
                                .padding(.bottom, theme.padding.bottom)
                        }
                        Divider()
                            .background(theme.text)
                            .padding(.horizontal, theme.spacing)
                        // ScrollViewReader enables programmatic scrolling to specific doors
                        ScrollViewReader { proxy in
                            ScrollView {
                                calendarGrid(width: geometry.size.width)
                                    .padding(.top, theme.padding.top)
                                    .padding(.bottom, theme.padding.bottom)
                            }
                            .scrollIndicators(.hidden)
                            // When the view appears, automatically scroll to the current door
                            .onAppear {
                                Task { @MainActor in
                                    // Small delay to ensure view is ready
                                    try? await Task.sleep(for: .milliseconds(300))
                                    if let doorToScrollTo = findCurrentDoor() {
                                        withAnimation {
                                            proxy.scrollTo(doorToScrollTo.id, anchor: .center)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            updateCountdown() // Initialize countdown immediately when view appears
            scheduleNotifications()
        }
        // Update countdown every second using the timer publisher
        .onReceive(timer) { _ in
            updateCountdown()
        }
    }
    
    // MARK: - UI Components
    
    // Background layer that displays either a custom image or default color
    private var backgroundLayer: some View {
        ZStack {
            if let backgroundData = calendar.backgroundImageData,
               let uiImage = UIImage(data: backgroundData) {
                GeometryReader { geo in
                    // Configures the background image with proper scaling and overlay
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill) // (might crop the image if aspect ratios don't match)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .overlay {
                            Color(colorScheme == .dark ? .black : .white).opacity(0.4) // adaptive overlay that changes with system theme
                        }
                        .position(x: geo.size.width / 2, y: geo.size.height / 2) // Center the image in the available space
                }
            } else {
                // Uses background color if set, otherwise use theme background
                calendar.backgroundColor
                    .overlay {
                        Color(colorScheme == .dark ? .black : .white).opacity(0.4)
                    }
                    .ignoresSafeArea()
            }
        }
    }
    
    // A view that displays a celebratory message when all doors have been unlocked
    private var completionView: some View {
        VStack(spacing: theme.spacing) {
            Image(systemName: "trophy.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(theme.accent)
            
            Text("Congratulations!")
                .font(theme.titleFont.bold())
                .foregroundColor(theme.text)
            
            Text("You've unlocked all the doors!")
                .font(theme.bodyFont)
                .foregroundColor(theme.text.opacity(0.8))
            
            Text("Thanks for sharing this journey")
                .font(theme.bodyFont)
                .foregroundColor(theme.text.opacity(0.6))
        }
        .padding()
        .background {
            // Semi-transparent background container
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.countdownStyle.backgroundColor)
                .shadow(color: theme.countdownStyle.shadowColor.opacity(0.15), radius: 6, x: 0, y: 3)
        }
    }
    
    // A view that displays the complete countdown timer for the next door
    // Combines multiple CountdownCells with separators and descriptive text
    private var countdownView: some View {
        return VStack(spacing: theme.spacing) {
            HStack(spacing: 4) {
                CountdownCell(value: countdown.days, label: "days")
                colonSeparator()
                CountdownCell(value: countdown.hours, label: "hours")
                colonSeparator()
                CountdownCell(value: countdown.minutes, label: "minutes")
            }
            
            Text("until Door \(findNextDoor()?.number ?? 0)!")
                .foregroundStyle(theme.text)
                .font(theme.bodyFont)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background {
            // Semi-transparent background container
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.countdownStyle.backgroundColor)
                .shadow(color: theme.countdownStyle.shadowColor.opacity(0.15), radius: 6, x: 0, y: 3)
        }
        
        // Separator view used between countdown cells
        func colonSeparator() -> some View {
            Text(":")
                .foregroundStyle(theme.countdownStyle.separatorColor)
                .font(theme.titleFont)
                .offset(y: -theme.spacing) // Adjust colon position to allign with the numbers
        }
    }
    
    // Creates the grid layout for calendar doors
    private func calendarGrid(width: CGFloat) -> some View {
        LazyVGrid(
            // Create an array of grid items, one for each column
            columns: Array(repeating: GridItem(.flexible(), spacing: theme.spacing),
                          count: calendar.gridColumns),
            spacing: theme.spacing
        ) {
            ForEach(calendar.doors) { door in
                DoorViewCell(isAnyDoorOpening: $isAnyDoorOpening, door: door, calendar: calendar)
                    .aspectRatio(1, contentMode: .fit) // Maintain square shape
            }
        }
        .padding(.horizontal, theme.padding.trailing)
    }
    
    // MARK: - Helper Functions
    
    // Checks if all doors in the calendar have been unlocked
    // Returns true if every door's isUnlocked property is true, false otherwise
    // Used to determine whether to show the completion view or countdown
    private func areAllDoorsUnlocked() -> Bool {
        calendar.doors.allSatisfy { $0.isUnlocked }
    }
    
    // Finds the door that corresponds to the current date
    private func findCurrentDoor() -> CalendarDoor? {
        let today = Calendar.current.startOfDay(for: Date())
        
        return calendar.doors.first { door in
            Calendar.current.isDate(today, inSameDayAs: door.unlockDate)
        }
    }
    
    // Finds the next unopened door that can be unlocked
    private func findNextDoor() -> CalendarDoor? {
        let now = Date()
        return calendar.doors
            .filter { door in
                door.unlockDate > now && !door.hasBeenOpened
            }
            .min { $0.unlockDate < $1.unlockDate }
    }
    
    // Updates the countdown timer values based on the next unlockable door
    private func updateCountdown() {
        if areAllDoorsUnlocked() {
            countdown = CountdownInfo()
            return
        }
        
        guard let nextDoor = findNextDoor() else {
            countdown = CountdownInfo()
            return
        }
        
        let now = Date()
        
        // Calculates full date components between now and the unlock date
        let components = Calendar.current.dateComponents(
            [.day, .hour, .minute],
            from: now,
            to: nextDoor.unlockDate
        )
        
        // If countdown reaches 00:00:00, update door states
        if components.day == 0 && components.hour == 0 && components.minute == 0 {
            for door in calendar.doors {
                var updatedDoor = door
                updatedDoor.updateUnlockState()
                CalendarStateManager.shared.silentlyUpdateDoor(updatedDoor)
            }
        }
        
        countdown = CountdownInfo(
            days: components.day ?? 0,
            hours: components.hour ?? 0,
            minutes: components.minute ?? 0
        )
    }
    
    // Schedules notifications for upcoming doors
    private func scheduleNotifications() {
        calendar.doors
            .filter { $0.unlockDate > Date() && !$0.hasBeenOpened }
            .forEach { door in
                NotificationManager.shared.scheduleDoorNotifications(for: door)
            }
    }
}

// MARK: - Preview

#Preview {
    TabViewCalendar(calendar: HolidayCalendar.createDefault())
}
