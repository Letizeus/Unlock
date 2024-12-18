import SwiftUI

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
