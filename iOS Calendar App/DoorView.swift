import SwiftUI

// View representing an individual door in the calendar
struct DoorView: View {
    
    // MARK: - Properties
    
    @State var door: CalendarDoor
    @State private var isShowingContent = false // Controls content sheet presentation
    private var isToday: Bool {
        Calendar.current.isDate(door.unlockDate, inSameDayAs: Date())
    }
    
    private var backgroundColor: Color {
        if isToday {
            return Constants.Colors.doorToday // Highlight today's door
        } else if door.isUnlocked {
            return Constants.Colors.doorUnlocked // Show unlocked doors
        } else {
            return Constants.Colors.doorLocked // Default state
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
    
    // MARK: - View Body
    
    var body: some View {
        Button(action: handleDoorTap) {
            ZStack {
                doorBackground
                doorNumber
            }
        }
        .sheet(isPresented: $isShowingContent) {
            DoorContentView(content: door.content)
        }
    }
    
    private var doorBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .aspectRatio(1, contentMode: .fit)
    }
    
    private var doorNumber: some View {
        VStack(spacing: 4) {
            Text("\(door.number)")
                .font(.title2)
                .bold()
                .foregroundStyle(textColor)
            // Show opened indicator for unlocked doors
            if door.isUnlocked {
                Image(systemName: door.hasBeenOpened ? "checkmark.circle.fill" : "checkmark.circle")
                    .foregroundStyle(.green)
                    .font(.system(size: 14))
            }
        }
    }

    private func handleDoorTap() {
        guard door.isUnlocked else { return }
        isShowingContent.toggle()
        door.hasBeenOpened = true
    }
}
