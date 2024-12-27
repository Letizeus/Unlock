import SwiftUI

// MARK: - TabViewEditor

// A view cell that displays a preview of a calendar door in the editor
// Used in the calendar creation interface to show door content types
struct DoorPreviewCell: View {
    
    @Environment(\.editorTheme) private var theme
    
    let door: CalendarDoor
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d. MMM"
        return formatter.string(from: door.unlockDate)
    }
    
    var body: some View {
        VStack {
            ZStack {
                // Background shape for the door
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(theme.previewStyle.backgroundColor)
                    .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 3)
                
                // Door number and content type display
                VStack(spacing: 4) {
                    Text("\(door.number)")
                        .font(theme.subtitleFont)
                        .bold()
                        .foregroundColor(theme.text)
                    Text(door.content.contentType)
                        .font(.footnote) // Note: When added to Protocol, Editor crashes
                        .foregroundColor(theme.text.opacity(0.6))
                    Text(formattedDate)
                        .font(.footnote) // Note: When added to Protocol, Editor crashes
                        .foregroundColor(theme.text.opacity(0.6))
                        .padding(.top, 2)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - TabViewCalendar

// Reusable view component for displaying a countdown value and its label
// Used to show days, hours, or minutes remaining until the next door unlock
struct CountdownCell: View {
    
    @Environment(\.calendarTheme) private var theme
    
    let value: Int
    let label: String // Label describing the value (e.g., "days", "hours")
    
    var body: some View {
        VStack(spacing: 2) {
            Text(String(format: "%02d", value)) // Add leading zero
                .font(theme.titleFont.bold())
                .foregroundStyle(theme.text)
            Text(label)
                .font(theme.bodyFont)
                .foregroundStyle(theme.text.opacity(0.8))
        }
        .frame(width: theme.countdownStyle.cellWidth)
    }
}

// A view that displays the complete countdown timer for the next door
// Combines multiple CountdownCells with separators and descriptive text
struct CountdownDisplay: View {
    
    @Environment(\.calendarTheme) private var theme
    
    let nextDoorNumber: Int
    let countdown: CountdownInfo
    
    var body: some View {
        VStack(spacing: theme.spacing) {
            HStack(spacing: 4) {
                CountdownCell(value: countdown.days, label: "days")
                colonSeparator
                CountdownCell(value: countdown.hours, label: "hours")
                colonSeparator
                CountdownCell(value: countdown.minutes, label: "minutes")
            }
            
            Text("until Door \(nextDoorNumber)!")
                .foregroundStyle(theme.text)
                .font(theme.bodyFont)
        }
        .padding()
        .background {
            // Semi-transparent background container
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.countdownStyle.backgroundColor)
                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
        }
    }
    
    // Separator view used between countdown cells
    private var colonSeparator: some View {
        Text(":")
            .foregroundStyle(theme.countdownStyle.separatorColor)
            .font(theme.titleFont)
            .offset(y: -theme.spacing) // Adjust colon position to allign with the numbers
    }
}

// ------------------------------------------------------------------------------------------------------

// View representing an individual door in the calendar
struct DoorViewCell: View {
    
    @Environment(\.calendarTheme) private var theme
    
    // Properties
    
    @State var door: CalendarDoor
    @State private var isShowingContent = false // Controls content sheet presentation
    @State private var doorRotation = 0.0
    @State private var doorOpacity = 1.0
    @State private var isPressed = false
    
    private var isToday: Bool {
        Calendar.current.isDate(door.unlockDate, inSameDayAs: Date())
    }
    
    private var backgroundColor: Color {
        if isToday {
            return theme.doorStyle.todayBackground // Highlight today's door
        } else if door.isUnlocked {
            return theme.doorStyle.unlockedBackground // Show unlocked doors
        } else {
            return theme.doorStyle.lockedBackground // Default state
        }
    }
    
    private var textColor: Color {
        if isToday || !door.isUnlocked {
            return theme.text
        } else {
            return theme.accent
        }
    }
    
    // View Body
    var body: some View {
        ZStack {
            suprise
                .opacity(1 - doorOpacity)
                .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
            // Door front
            doorFront
                .opacity(doorOpacity)
                .rotation3DEffect(
                    .degrees(doorRotation),
                    axis: (x: 0, y: 0, z: 1),
                    anchor: .center
                )
        }
        .aspectRatio(1, contentMode: .fit)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        // Handle tap interaction
        .onTapGesture {
            if door.isUnlocked {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    isPressed = true
                }
                // Reset the pressed state after a short delay and trigger door opening
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                    handleDoorTap()
                }
            }
        }
        // Only allow interaction with unlocked doors
        .allowsHitTesting(door.isUnlocked)
        // Present content sheet when door is opened
        .sheet(isPresented: $isShowingContent) {
            DoorContentView(content: door.content)
        }
        // Checks unlock state when view appears
        .onAppear {
            updateUnlockState()
        }
    }
    
    // UI Components
    
    // The gift preview view that appears behind the door
    private var suprise: some View {
        RoundedRectangle(cornerRadius: theme.cornerRadius)
            .fill(theme.background.opacity(0.9))
            .overlay(
                Image(systemName: "gift.fill")
                    .font(.system(size: 24))
                    .foregroundColor(theme.accent)
            )
            .shadow(radius: 5)
    }
    
    // The front face of the door including number and completion status
    private var doorFront: some View {
        RoundedRectangle(cornerRadius: theme.cornerRadius)
            .fill(backgroundColor)
            .overlay(
                VStack(spacing: 4) {
                    Text("\(door.number)")
                        .font(theme.subtitleFont)
                        .bold()
                        .foregroundStyle(textColor)
                    // Show checkmark for opened doors
                    if door.isUnlocked && door.hasBeenOpened {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(theme.accent)
                            .font(theme.bodyFont)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(theme.doorStyle.borderColor, lineWidth: theme.doorStyle.borderWidth)
            )
            .shadow(color: Color.black.opacity(door.isUnlocked ? 0.3 : 0.15), radius: 5, x: 0, y: 3)
    }
    
    // Helper Methods
    
    // Checks if the door should be unlocked
    private func updateUnlockState() {
        door.isUnlocked = Calendar.current.startOfDay(for: Date()) >= Calendar.current.startOfDay(for: door.unlockDate)
    }
    
    // Door tap handler
    private func handleDoorTap() {
        guard door.isUnlocked else { return }
        
        // Animate door opening
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            doorRotation = 180 // Rotate half turn
            doorOpacity = 0.0 // Fade out door to see content
        }
        
        // Show content sheet after the door animation
        // Schedule code execution after a delay of 0.5 seconds
        // - Uses the main dispatch queue to ensure UI updates happen on the main thread
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isShowingContent = true
            door.hasBeenOpened = true
            door.isUnlocked = true
            
            // Reset door after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    doorRotation = 0
                    doorOpacity = 1.0
                }
            }
        }
    }
}

// ------------------------------------------------------------------------------------------------------

// creates an overlay color that adapts to the system theme
struct AdaptiveOverlay: View {
    @Environment(\.colorScheme) var scheme
    
    var body: some View {
        Color(scheme == .dark ? .black : .white)
            .opacity(0.4)
    }
}

// MARK: - TabViewMap


