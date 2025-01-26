import SwiftUI

// MARK: - Helper Functions

private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "d MMM"
    return formatter.string(from: date)
}

// MARK: - TabViewEditor

// A view cell that displays a preview of a calendar door in the editor
// Used in the calendar editor interface to show door content types
struct DoorPreviewCell: View {
    
    @Environment(\.editorTheme) private var theme
    
    let door: CalendarDoor
    
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
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    contentIcon
                        .font(.system(size: 20))
                        .foregroundColor(theme.text.opacity(0.6))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    Text(formatDate(door.unlockDate))
                        .font(theme.footnoteFont)
                        .foregroundColor(theme.text.opacity(0.6))
                        .padding(.top, 2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private var contentIcon: Image {
        switch door.content {
        case .text:
            Image(systemName: "text.bubble")
        case .image:
            Image(systemName: "photo")
        case .video:
            Image(systemName: "video.fill")
        }
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
            // Number display
            Text(String(format: "%02d", value)) // Adds leading zero
                .font(theme.subtitleFont.bold())
                .foregroundStyle(theme.text)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(.vertical, 6)
                .frame(minWidth: theme.countdownStyle.cellWidth)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .fill(theme.secondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.cornerRadius)
                                .stroke(theme.doorStyle.borderColor, lineWidth: 1)
                        )
                )
                .shadow(color: theme.doorStyle.shadowColor.opacity(0.1), radius: 3, x: 0, y: 2)
            // Label text
            Text(label.uppercased())
                .font(theme.captionFont)
                .fontWeight(.medium)
                .foregroundStyle(theme.text.opacity(0.8))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .tracking(1)
        }
        .frame(minWidth: theme.countdownStyle.cellWidth)
    }
}

// MARK: -

// View representing an individual door in the calendar
struct DoorViewCell: View {
    
    @Environment(\.calendarTheme) private var theme
    
    // Properties
    
    @Binding var isAnyDoorOpening: Bool
    @StateObject private var manager: DoorOpeningManager
    let calendar: HolidayCalendar
    
    private var isToday: Bool {
        Calendar.current.isDate(manager.door.unlockDate, inSameDayAs: Date())
    }
    
    private var backgroundColor: Color {
        if manager.door.hasBeenOpened {
            return calendar.doorColor != .clear ? calendar.doorColor : theme.doorStyle.completedBackground
        } else if isToday {
            return calendar.doorColor != .clear ? calendar.doorColor.opacity(0.8) : theme.doorStyle.todayBackground
        } else if manager.door.isUnlocked {
            return calendar.doorColor != .clear ? calendar.doorColor.opacity(0.5) : theme.doorStyle.unlockedBackground
        } else {
            return theme.doorStyle.lockedBackground
        }
    }
    
    private var textColor: Color {
        if isToday || !manager.door.isUnlocked {
            return theme.text
        } else {
            let baseColor = calendar.doorColor != .clear ? calendar.doorColor : theme.accent
            return baseColor.mix(with: theme.text, by: 0.5)
        }
    }
    
    // Initialization
    
    init(isAnyDoorOpening: Binding<Bool>, door: CalendarDoor, calendar: HolidayCalendar) {
        self._isAnyDoorOpening = isAnyDoorOpening
        self._manager = StateObject(wrappedValue: DoorOpeningManager(door: door, isAnyDoorOpening: isAnyDoorOpening))
        self.calendar = calendar
    }
    
    // View Body
    
    var body: some View {
        ZStack {
            surprise
                .opacity(1 - manager.doorOpacity)
                .shadow(color: theme.doorStyle.shadowColor.opacity(0.2), radius: 6, x: 0, y: 3)
            // Door front
            doorFront
                .opacity(manager.doorOpacity)
                .rotation3DEffect(
                    .degrees(manager.doorRotation),
                    axis: (x: 0, y: 0, z: 1),
                    anchor: .center
                )
        }
        .aspectRatio(1, contentMode: .fit)
        .doorInteraction(manager: manager) {
            isAnyDoorOpening = false
        }
    }
    
    // UI Components
    
    // The gift preview view that appears behind the door
    private var surprise: some View {
        RoundedRectangle(cornerRadius: theme.cornerRadius)
            .fill(calendar.doorColor != .clear ? calendar.doorColor : theme.doorStyle.completedBackground)
            .overlay(
                Image(systemName: "gift.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            )
    }
    
    // The front face of the door including number and completion status
    private var doorFront: some View {
        RoundedRectangle(cornerRadius: theme.cornerRadius)
            .fill(backgroundColor)
            .overlay(
                VStack(spacing: 4) {
                    // Show checkmark for opened doors
                    if manager.door.isUnlocked && manager.door.hasBeenOpened {
                        Image(systemName: "giftcard.fill")
                            .foregroundStyle(.white)
                            .font(theme.bodyFont)
                    } else {
                        Text("\(manager.door.number)")
                            .font(theme.subtitleFont)
                            .bold()
                            .foregroundStyle(textColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .multilineTextAlignment(.center)
                        
                        Text(formatDate(manager.door.unlockDate))
                            .font(theme.footnoteFont)
                            .foregroundStyle(textColor.opacity(0.8))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .multilineTextAlignment(.center)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(theme.doorStyle.borderColor, lineWidth: theme.doorStyle.borderWidth)
            )
            .shadow(color: theme.doorStyle.shadowColor.opacity(manager.door.isUnlocked ? 0.3 : 0.15), radius: 5, x: 0, y: 3)
    }
}
// MARK: - TabViewMap

// CheckpointNodeView represents a single node (door) in the map journey visualization.
struct CheckpointNodeView: View {
    
    @Environment(\.mapTheme) private var theme
    
    // Properties
    
    @Binding var isAnyDoorOpening: Bool
    @StateObject private var manager: DoorOpeningManager
    
    private let checkpointSize: CGFloat = 80
    
    // Determines the checkpoint's background color based on its state
    private var doorColor: Color {
        if manager.door.hasBeenOpened {
            return theme.checkpointStyle.completedColor
        } else if manager.door.isUnlocked {
            return theme.checkpointStyle.unlockedColor
        } else {
            return theme.checkpointStyle.lockedColor
        }
    }
    
    // Determines which SF Symbol to display based on door state
    private var iconName: String {
        if manager.door.hasBeenOpened {
            return "giftcard.fill"
        } else if manager.door.isUnlocked && manager.doorOpacity == 0.0 {
            return "gift.fill"
        } else if manager.door.isUnlocked {
            return "lock.open.fill"
        } else {
            return "lock.fill"
        }
    }
    
    // Initialization
    
    init(isAnyDoorOpening: Binding<Bool>, door: CalendarDoor) {
        self._isAnyDoorOpening = isAnyDoorOpening
        self._manager = StateObject(wrappedValue: DoorOpeningManager(door: door, isAnyDoorOpening: isAnyDoorOpening))
    }
    
    var body: some View {
        HStack {
            // Left side: Display the unlock date
            Text(formatDate(manager.door.unlockDate))
                .font(theme.bodyFont)
                .frame(width: theme.dateLabelStyle.width)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            Spacer()
            
            // Center: Checkpoint circle with animation states
            ZStack {
                if manager.door.isUnlocked {
                    // Background gift that shows during animation
                    Circle()
                        .fill(theme.checkpointStyle.unlockedColor)
                        .frame(width: theme.checkpointStyle.size, height: theme.checkpointStyle.size)
                        .overlay(
                            Image(systemName: "gift.fill")
                                .font(.system(size: theme.checkpointStyle.iconSize))
                                .foregroundColor(.white)
                        )
                        .opacity(1 - manager.doorOpacity)
                }
                
                checkpointFront
                    // Apply 3D rotation effect during opening animation
                    .rotation3DEffect(
                        .degrees(manager.doorRotation),
                        axis: (x: 0, y: 0, z: 1),
                        anchor: .center
                    )
                    .opacity(manager.doorOpacity)
            }
            
            Spacer()
            
            // Right side: Display door number
            Text("\(manager.door.number). Gift")
                .font(theme.bodyFont)
                .foregroundColor(theme.text.opacity(0.6))
                .frame(width: theme.dateLabelStyle.width)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
        }
        .doorInteraction(manager: manager) {
            isAnyDoorOpening = false
        }
    }
    
    // The front face of the checkpoint including icon and visual states
    private var checkpointFront: some View {
        // Front face that rotates
        ZStack {
            // Main circle background
            Circle()
                .fill(doorColor)
                .frame(width: theme.checkpointStyle.size, height: theme.checkpointStyle.size)
                .shadow(radius: manager.door.isUnlocked ? theme.checkpointStyle.shadowRadius : theme.checkpointStyle.shadowRadius / 2)
            
            // Inner circle for depth effect
            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: theme.checkpointStyle.size * 0.8, height: theme.checkpointStyle.size * 0.8)
            
            // State icon (lock, gift, or star)
            Image(systemName: iconName)
                .font(.system(size: theme.checkpointStyle.iconSize))
                .foregroundColor(.white)
        }
    }
}
