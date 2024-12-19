import SwiftUI

// View representing an individual door in the calendar
struct DoorViewCell: View {
    
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
        .aspectRatio(1, contentMode: .fit)
        .sheet(isPresented: $isShowingContent) {
            DoorContentView(content: door.content)
        }
    }
    
    // MARK: - UI Components
    
    private var doorBackground: some View {
        RoundedRectangle(cornerRadius: Constants.UI.defaultCornerRadius)
            .fill(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.UI.defaultCornerRadius)
                    .stroke(Constants.Colors.borderColor, lineWidth: 1)
            )
            .aspectRatio(1, contentMode: .fit)
    }
    
    private var doorNumber: some View {
        VStack(spacing: 4) {
            Text("\(door.number)")
                .font(.title2)
                .bold()
                .foregroundStyle(textColor)
            if door.isUnlocked {
                Image(systemName: door.hasBeenOpened ? "checkmark.circle.fill" : "checkmark.circle")
                    .foregroundStyle(.green)
                    .font(.system(size: Constants.UI.bodyFontSize))
            }
        }
    }
    
    // MARK: - Helper Methods

    private func handleDoorTap() {
        guard door.isUnlocked else { return }
        isShowingContent.toggle()
        door.hasBeenOpened = true
    }
}

// MARK: - Door View Content

// View for displaying the content behind an opened door
struct DoorContentView: View {
    let content: DoorContent
    @Environment(\.dismiss) private var dismiss // For dismissing the sheet
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    // Display different content types
                    switch content {
                    case .text(let text):
                        Text(text)
                            .padding()
                    case .image(let imageName):
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                    case .video(_):
                        Text("Video Player Placeholder")
                    case .map(_, _):
                        Text("Map View Placeholder")
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
