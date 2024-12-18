import SwiftUI

// View representing an individual door in the calendar
struct DoorView: View {
    let door: CalendarDoor
    @State private var isShowingContent = false // Controls content sheet presentation
    @State private var hasBeenOpened = false // New state to track if door has been opened    
    // Get current date components for highlighting today's door
    private var isToday: Bool {
        Calendar.current.isDate(door.unlockDate, inSameDayAs: Date())
    }
    
    private var backgroundColor: Color {
        if isToday {
            return .yellow.opacity(0.3) // Highlight today's door
        } else if door.isUnlocked {
            return .green.opacity(0.2) // Show unlocked doors
        } else {
            return .white.opacity(0.15) // Default state
        }
    }
    
    private var textColor: Color {
        if isToday {
            return .white
        } else if door.isUnlocked {
            return .green
        } else {
            return .white
        }
    }
    
    var body: some View {
        Button {
            if door.isUnlocked {
                isShowingContent.toggle()
                hasBeenOpened = true // Mark as opened when content is shown
            }
        } label: {
            ZStack {
                // Door background and border
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .aspectRatio(1, contentMode: .fit)
                
                VStack(spacing: 4) {
                    // Door number
                    Text("\(door.number)")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(textColor)
                    
                    // Show opened indicator for unlocked doors
                    if door.isUnlocked {
                        Image(systemName: hasBeenOpened ? "checkmark.circle.fill" : "checkmark.circle")
                            .foregroundStyle(.green)
                            .font(.system(size: 14))
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingContent) {
            DoorContentView(content: door.content)
        }
    }
}
