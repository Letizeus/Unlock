import SwiftUI

// MARK: - TabViewEditor

// A view cell that displays a preview of a calendar door in the editor
// Used in the calendar creation interface to show door content types
struct DoorPreviewCell: View {
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
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.tertiarySystemBackground))
                
                // Door number and content type display
                VStack(spacing: 4) {
                    Text("\(door.number)")
                        .font(.title2)
                        .bold()
                    Text(door.content.contentType)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formattedDate)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
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
    let value: Int
    let label: String // Label describing the value (e.g., "days", "hours")
    
    var body: some View {
        VStack(spacing: 2) {
            Text(String(format: "%02d", value)) // Add leading zero
                .font(.system(size: Constants.UI.titleFontSize, weight: .bold))
                .foregroundStyle(Constants.Colors.whiteText)
            Text(label)
                .font(.system(size: Constants.UI.bodyFontSize))
                .foregroundStyle(Constants.Colors.whiteText.opacity(0.8))
        }
        .frame(width: Constants.UI.countdownCellWidth)
    }
}

// A view that displays the complete countdown timer for the next door
// Combines multiple CountdownCells with separators and descriptive text
struct CountdownDisplay: View {
    let nextDoorNumber: Int
    let countdown: CountdownInfo
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                CountdownCell(value: countdown.days, label: "days")
                colonSeparator
                CountdownCell(value: countdown.hours, label: "hours")
                colonSeparator
                CountdownCell(value: countdown.minutes, label: "minutes")
            }
            
            Text("until Door \(nextDoorNumber)!")
                .foregroundStyle(Constants.Colors.whiteText)
                .font(.system(size: Constants.UI.subtitleFontSize))
        }
        .padding()
        .background {
            // Semi-transparent background container
            RoundedRectangle(cornerRadius: Constants.UI.defaultCornerRadius)
                .fill(Constants.Colors.lightOverlay)
        }
        .padding(.horizontal)
    }
    
    // Separator view used between countdown cells
    private var colonSeparator: some View {
        Text(":")
            .foregroundStyle(.white)
            .font(.system(size: 24, weight: .bold))
            .offset(y: -8) // Adjust colon position to allign with the numbers
    }
}

// MARK: - TabViewMap


