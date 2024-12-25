import SwiftUI

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
