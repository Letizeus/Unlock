import SwiftUI

struct TabViewCalendar: View {
    
    @Environment(\.calendarTheme) private var theme // Access the calendar theme from the environment
    
    // MARK: - Properties
    
    // The calendar data model containing all doors and their content
    let calendar: HolidayCalendar
    // Current countdown information (days, hours, minutes)
    @State private var countdown = CountdownInfo()
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
                        ScrollView() {
                            calendarGrid(width: geometry.size.width)
                        }
                    }
                    .padding(.vertical)
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
                            AdaptiveOverlay() // adaptive overlay that changes with system theme
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
        Group {
            if let nextDoor = findNextDoor() {
                CountdownDisplay(
                    nextDoorNumber: nextDoor.number,
                    countdown: countdown
                )
            }
        }
    }
    
    // Creates the grid layout for calendar doors
    // This function also calculates the optimal size for door cells
    // width parameter: Available width for the grid
    private func calendarGrid(width: CGFloat) -> some View {
        let spacing = theme.spacing // Space between each door cell (vertical and horizontal)
        let padding = (theme.padding.leading + theme.padding.trailing) // Padding on left and right edges of the entire grid
        let availableWidth = width - padding // Calculate actual width available for the grid after padding
        // Calculate total space used by gaps between cells
        // Example: For 4 columns, we need 3 gaps (columns - 1)
        let totalSpacing = spacing * CGFloat(calendar.gridColumns - 1)
        let cellSize = (availableWidth - totalSpacing) / CGFloat(calendar.gridColumns) // Calculate size of each cell to fit perfectly in the grid
        
        return LazyVGrid(
            // Create an array of grid items, one for each column
            // .fixed ensures all cells have the exact same width (cellSize)
            columns: Array(repeating: GridItem(.fixed(cellSize), spacing: spacing),
                          count: calendar.gridColumns),
            spacing: spacing
        ) {
            ForEach(calendar.doors) { door in
                DoorViewCell(door: door)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Finds the next unopened door that can be unlocked
    private func findNextDoor() -> CalendarDoor? {
        return calendar.doors
            .filter { !$0.isUnlocked && $0.unlockDate > Date() }
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
