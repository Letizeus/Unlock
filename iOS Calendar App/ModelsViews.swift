import SwiftUI

// MARK: - TabViewEditor

// A view cell that displays a preview of a calendar door in the editor
// Used in the calendar creation interface to show door content types
struct DoorPreviewCell: View {
    
    @Environment(\.editorTheme) private var theme
    
    let door: CalendarDoor
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: door.unlockDate)
    }
    
    var body: some View {
        VStack {
            ZStack {
                // Background shape for the door
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(theme.previewStyle.backgroundColor)
                
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

// View representing an individual door in the calendar
struct DoorViewCell: View {
    
    @Environment(\.calendarTheme) private var theme
    
    // Properties
    
    @State var door: CalendarDoor
    @State private var isShowingContent = false // Controls content sheet presentation
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
        Button(action: handleDoorTap) {
            ZStack {
                doorBackground
                doorNumber
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .sheet(isPresented: $isShowingContent) {
            DoorContentView(content: door.content)
        }
    }
    
    // UI Components
    private var doorBackground: some View {
        RoundedRectangle(cornerRadius: theme.cornerRadius)
            .fill(backgroundColor)
            .overlay(
                alignment: .center,
                content: {
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .stroke(theme.doorStyle.borderColor, lineWidth: theme.doorStyle.borderWidth)
                }
            )
            .aspectRatio(1, contentMode: .fit)
    }
    
    private var doorNumber: some View {
        VStack(spacing: 4) {
            Text("\(door.number)")
                .font(theme.subtitleFont)
                .bold()
                .foregroundStyle(textColor)
            if door.isUnlocked {
                Image(systemName: door.hasBeenOpened ? "checkmark.circle.fill" : "checkmark.circle")
                    .foregroundStyle(theme.accent)
                    .font(theme.bodyFont)
            }
        }
    }
    
    // Helper Methods
    private func handleDoorTap() {
        guard door.isUnlocked else { return }
        isShowingContent.toggle()
        door.hasBeenOpened = true
    }
}

// View for displaying the content behind an opened door
struct DoorContentView: View {
    
    @Environment(\.calendarTheme) private var theme
    @Environment(\.dismiss) private var dismiss // For dismissing the sheet
    
    let content: DoorContent
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    // Display different content types
                    switch content {
                    case .text(let text):
                        Text(text)
                            .font(theme.bodyFont)
                            .foregroundColor(theme.text)
                            .padding(theme.padding)
                    case .image(let imageName):
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                    case .video(_):
                        Text("Video Player Placeholder")
                            .font(theme.bodyFont)
                            .foregroundColor(theme.text)
                    case .map(_, _):
                        Text("Map View Placeholder")
                            .font(theme.bodyFont)
                            .foregroundColor(theme.text)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - TabViewMap


