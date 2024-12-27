import SwiftUI

struct TabViewCalendar: View {
    
    @Environment(\.calendarTheme) private var theme // Access the calendar theme from the environment
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Properties
    
    // The calendar data model containing all doors and their content
    let calendar: HolidayCalendar
    // Current countdown information (days, hours, minutes)
    @State private var countdown = CountdownInfo()
    // Only one door at once
    @State private var isAnyDoorOpening = false
    // Timer that updates the countdown every second
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // MARK: - View Body
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in // GeometryReader provides access to the parent view's dimensions
                ZStack {
                    backgroundLayer
                        .edgesIgnoringSafeArea(.all)
                    
                    // Main content layout including title, countdown and calendar grid
                    VStack(spacing: theme.spacing) {
                        Text(calendar.title)
                            .font(theme.titleFont)
                            .bold()
                            .foregroundStyle(theme.text)
                            .padding(.top, theme.padding.top)
                        
                        countdownView
                        // ScrollViewReader enables programmatic scrolling to specific doors
                        ScrollViewReader { proxy in
                            ScrollView() {
                                calendarGrid(width: geometry.size.width)
                                    .padding(.top, theme.padding.top)
                                    .padding(.bottom, theme.padding.bottom)
                            }
                            // When the view appears, automatically scroll to the current door
                            .onAppear {
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
        // Initialize countdown immediately when view appears
        .onAppear(perform: updateCountdown)
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
                theme.background
            }
        }
    }
    
    // Displays the countdown to the next unlockable door
    private var countdownView: some View {
        let nextDoor = findNextDoor()
        return CountdownDisplay(
            nextDoorNumber: nextDoor?.number ?? 0,
            countdown: countdown
        )
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
                DoorViewCell(isAnyDoorOpening: $isAnyDoorOpening, door: door)
                    .aspectRatio(1, contentMode: .fit) // Maintain square shape
            }
        }
        .padding(.horizontal, theme.padding.trailing)
    }
    
    // MARK: - Helper Methods
    
    // Finds the door that corresponds to the current date
    private func findCurrentDoor() -> CalendarDoor? {
        let today = Calendar.current.startOfDay(for: Date())
        
        return calendar.doors.first { door in
            Calendar.current.isDate(today, inSameDayAs: door.unlockDate)
        }
    }
    
    // Finds the next unopened door that can be unlocked
    private func findNextDoor() -> CalendarDoor? {
        let now = Calendar.current.startOfDay(for: Date())
        return calendar.doors
            .filter { door in
                let doorDate = Calendar.current.startOfDay(for: door.unlockDate)
                return doorDate > now && !door.isUnlocked
            }
            .min { $0.unlockDate < $1.unlockDate }
    }
    
    // Updates the countdown timer values based on the next unlockable door
    func updateCountdown() {
        guard let nextDoor = findNextDoor() else {
            countdown = CountdownInfo()
            return
        }
        
        let components = Calendar.current.dateComponents(
            [.day, .hour, .minute],
            from: Date(),
            to: nextDoor.unlockDate
        )
        
        countdown = CountdownInfo(
            days: components.day ?? 0,
            hours: components.hour ?? 0,
            minutes: components.minute ?? 0
        )
    }
}

// MARK: - Preview

#Preview {
    TabViewCalendar(calendar: HolidayCalendar.createDefault())
}
