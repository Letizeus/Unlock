import SwiftUI

// View for displaying the content behind an opened door
struct DoorContentView: View {
    @Environment(\.calendarTheme) private var theme
    @Environment(\.dismiss) private var dismiss // For dismissing the sheet
    
    // MARK: - Properties
    
    let content: DoorContent
    var door: CalendarDoor
    let onReactionAdded: (String) -> Void // Callback function called when user adds a new reaction
    
    @State private var isImageExpanded = false // State for image expansion animation
    @State private var showReactionSheet = false // Controls the presentation of the reaction sheet
    @State private var hasReacted = false
    
    private let reactions = ["❤️", "👍🏼", "🎁", "⭐️", "🤩"]
    
    // Generate a simple device ID (only a temp solution)
    private let userId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    
    // MARK: - View Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing) {
                    // Display selected reaction at the top if one exists
                    if !door.reactions.isEmpty {
                        reactionCountsView
                            .padding(.top, theme.spacing)
                    }
                    
                    // Main content
                    contentView
                        .padding(.horizontal, theme.padding.leading)
                    
                    // Reaction button (only shown if user hasn't reacted)
                    if !door.hasReacted(userId: userId) {
                        Button(action: { showReactionSheet = true }) {
                            Label("Add Reaction", systemImage: "heart")
                                .font(theme.bodyFont)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(theme.accent)
                                .cornerRadius(20)
                        }
                        .padding(.top, theme.spacing)
                    }
                    
                    if door.hasReacted(userId: userId) {
                        Text("Thanks for spreading love!")
                            .font(theme.bodyFont)
                            .foregroundColor(theme.text.opacity(0.6))
                            .padding(.top, theme.spacing)
                    }
                    
                    Spacer(minLength: theme.spacing)
                }
                .padding(.vertical, theme.spacing)
            }
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(theme.text.opacity(0.6))
                            .font(.system(size: 24))
                    }
                }
            }
            .sheet(isPresented: $showReactionSheet) {
                reactionSheet
            }
        }
    }
    
    // MARK: - UI Components
    
    // Displays counts of all reactions for this door
    private var reactionCountsView: some View {
        let counts = door.reactionCounts()
        return HStack(spacing: theme.spacing) {
            ForEach(Array(counts.keys.sorted()), id: \.self) { emoji in
                if let count = counts[emoji] {
                    Text("\(emoji) \(count)")
                        .font(theme.bodyFont)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(theme.secondary)
                        .cornerRadius(theme.cornerRadius)
                }
            }
        }
    }
        
    // Switches between different content views based on the content type
    private var contentView: some View {
        VStack(spacing: theme.spacing) {
            switch content {
            case .text(let text):
                textContent(text)
            case .image(let imageName):
                imageContent(imageName)
            case .video(let videoURL):
                videoContent(videoURL)
            case .map(let latitude, let longitude):
                locationContent(latitude: latitude, longitude: longitude)
            }
        }
    }
    
    // Displays text content with proper formatting and styling
    private func textContent(_ text: String) -> some View {
        Text(text)
            .font(theme.bodyFont)
            .foregroundColor(theme.text)
            .multilineTextAlignment(.center)
            .padding(theme.padding)
            .frame(maxWidth: .infinity)
            .background(theme.secondary)
            .cornerRadius(theme.cornerRadius)
    }
    
    // Displays image content with tap-to-expand functionality
    private func imageContent(_ imageName: String) -> some View {
        GeometryReader { geometry in
            VStack {
                if let uiImage = UIImage(named: imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: isImageExpanded ? geometry.size.width : geometry.size.width * 0.8)
                        .cornerRadius(theme.cornerRadius)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isImageExpanded.toggle()
                            }
                        }
                } else {
                    // Fallback view when image cannot be loaded
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(theme.text.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .background(theme.secondary)
                        .cornerRadius(theme.cornerRadius)
                }
            }
        }
        .frame(height: 200)
    }
    
    // Displays a placeholder for video content
    private func videoContent(_ videoURL: String) -> some View {
        VStack {
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.secondary)
                .aspectRatio(16/9, contentMode: .fit)
                .overlay {
                    VStack(spacing: theme.spacing) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(theme.accent)
                        Text("Video Content")
                            .font(theme.bodyFont)
                            .foregroundColor(theme.text.opacity(0.6))
                    }
                }
        }
    }
    
    // Displays location information with coordinates
    private func locationContent(latitude: Double, longitude: Double) -> some View {
        VStack(spacing: theme.spacing / 2) {
            Image(systemName: "map")
                .font(.system(size: 44))
                .foregroundColor(theme.accent)
            Text("Location")
                .font(theme.bodyFont)
            Text("Lat: \(String(format: "%.4f", latitude))")
                .font(theme.bodyFont)
            Text("Long: \(String(format: "%.4f", longitude))")
                .font(theme.bodyFont)
        }
        .padding(theme.padding)
        .frame(maxWidth: .infinity)
        .background(theme.secondary)
        .cornerRadius(theme.cornerRadius)
    }
        
    // Sheet that appears when user wants to add a reaction
    private var reactionSheet: some View {
        VStack(spacing: theme.spacing) {
            Text("Choose a Reaction")
                .font(theme.titleFont.bold())
                .foregroundColor(theme.text)
                .padding(.top)
            
            // Grid of available reactions
            HStack(spacing: theme.spacing) {
                ForEach(reactions, id: \.self) { reaction in
                    Button(action: {
                        onReactionAdded(reaction)
                        hasReacted = true
                        showReactionSheet = false
                    }) {
                        Text(reaction)
                            .font(.system(size: 44))
                    }
                }
            }
            .padding()
            
            // Cancel button
            Button("Cancel") {
                showReactionSheet = false
            }
            .font(theme.bodyFont)
            .foregroundColor(.blue)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(theme.secondary)
            .cornerRadius(theme.cornerRadius)
            .padding(.bottom)
        }
        .padding(theme.padding)
        .presentationBackground(theme.secondary)
        .presentationDetents([.height(250)])
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DoorContentView(
            content: .text("✨ Lorem ipsum dolor sit amet! ✨\n\nConsectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. 🌟"),
            door: CalendarDoor(
                number: 1,
                unlockDate: Date(),
                isUnlocked: true,
                content: .text("✨ Lorem ipsum dolor sit amet! ✨\n\nConsectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. 🌟"),
                hasBeenOpened: true
            ),
            onReactionAdded: { _ in }
        )
        .environment(\.calendarTheme, CalendarTheme.default)
    }
}
