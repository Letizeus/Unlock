import SwiftUI
import AVKit

// View for displaying the content behind an opened door
struct DoorContentView: View {
    @Environment(\.calendarTheme) private var theme
    @Environment(\.dismiss) private var dismiss // For dismissing the sheet
    
    // MARK: - Properties
    
    let content: DoorContent
    var door: CalendarDoor
    let onReactionAdded: (String) -> Void // Callback function called when user adds a new reaction
    
    @State private var showReactionSheet = false // Controls the presentation of the reaction sheet
    @State private var hasReacted = false
    
    private let reactions = ["❤️", "👍🏼", "🎁", "⭐️", "🤩"]
    
    // Generate a simple device ID (only a temp solution)
    private let userId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    
    @State private var isLoadingVideo = false // Indicates if a video is currently loading
    
    @State private var isFullscreen = false // Indicates if an image is currently in full-screen
    
    // MARK: - View Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing) {
                    banner
                    
                    // Display selected reaction at the top if one exists
                    if !door.reactions.isEmpty {
                        reactionCountsView
                            .padding(.top, theme.spacing)
                    }
                    
                    // Main content
                    contentView
                        .padding(.horizontal, theme.padding.leading)
                    
                    reactionControls
                    
                    Spacer(minLength: theme.spacing)
                }
                .padding(.vertical, theme.spacing)
            }
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Leading: Share Button
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { /* Share functionality placeholder */ }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.blue)
                    }
                }
                // Trailing: Close Button
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(theme.text.opacity(0.6))
                    }
                }
            }
            .sheet(isPresented: $showReactionSheet) {
                reactionSheet
            }
        }
    }
    
    // MARK: - UI Components
    
    // Banner that always shows at the top
    private var banner: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.system(size: 44))
                .foregroundStyle(theme.accent)
                .minimumScaleFactor(0.75)
                .lineLimit(2)
            
            Text("Your Special Gift for Day \(door.number)")
                .font(theme.subtitleFont.bold())
                .foregroundColor(theme.text)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .cornerRadius(theme.cornerRadius)
        .padding(.horizontal)
    }
    
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
            case .image(let filename):
                // Loads image from AppStorage
                if let imageData = AppStorage.shared.loadMedia(identifier: filename),
                   let uiImage = UIImage(data: imageData) {
                    imageContent(uiImage: uiImage)
                } else {
                    missingImageContent
                }
            case .video(let filename):
                // Loads video from AppStorage
                if let videoData = AppStorage.shared.loadMedia(identifier: filename) {
                    videoContent(videoData: videoData)
                } else {
                    missingVideoContent
                }
            }
        }
    }
    
    // Displays text content
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
    
    // Displays image content
    private func imageContent(uiImage: UIImage) -> some View {
        GeometryReader { geo in
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .cornerRadius(theme.cornerRadius)
                .frame(width: geo.size.width, height: geo.size.height)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .onTapGesture {
                    isFullscreen = true
                }
        }
        .frame(height: UIScreen.main.bounds.width / (uiImage.size.width / uiImage.size.height))
        .fullScreenCover(isPresented: $isFullscreen) {
            ZStack {
                Color.black.ignoresSafeArea()
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    isFullscreen = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(theme.subtitleFont)
                        .foregroundStyle(theme.text.opacity(0.6))
                        .padding()
                }
            }
        }
    }
    
    // Fallback view for missing images
    private var missingImageContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "livephoto.slash")
                .font(.system(size: 40))
                .foregroundColor(theme.text.opacity(0.5))
            Text("Image not available")
                .font(theme.bodyFont)
                .foregroundColor(theme.text.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.secondary)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
    }
    
    // Displays video content
    private func videoContent(videoData: Data) -> some View {
        GeometryReader { geo in
            VStack {
                if isLoadingVideo {
                    // Displays a loading indicator while the video is being prepared
                    VStack {
                        ProgressView()
                            .padding(.bottom, 4)
                        Text("Preparing Video...")
                            .font(theme.bodyFont)
                            .foregroundColor(theme.text)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                } else {
                    // Creates a temporary file URL for the video data
                    let temporaryFileURL = AppStorage.shared.createTemporaryVideoFile(with: videoData)
                    
                    // If the temporary file URL is successfully created, display the video player
                    if let videoURL = temporaryFileURL {
                        VideoViewController(url: videoURL)
                            .aspectRatio(16/9, contentMode: .fit)
                            .cornerRadius(theme.cornerRadius)
                            .onDisappear {
                                // Cleans up the temporary video file when the view disappears
                                try? FileManager.default.removeItem(at: videoURL)
                            }
                            .frame(width: geo.size.width, height: geo.size.height)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    } else {
                        // If the temporary file URL creation fails, display the missing video content
                        missingVideoContent
                            .frame(width: geo.size.width, height: geo.size.height)
                    }
                }
            }
        }
        .frame(height: UIScreen.main.bounds.width * 9/16)
        .onAppear {
            isLoadingVideo = true
            // Adds a small delay to let the UI update
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isLoadingVideo = false
            }
        }
    }
    
    // Fallback view for missing videos
    private var missingVideoContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "video.slash")
                .font(.system(size: 40))
                .foregroundColor(theme.text.opacity(0.5))
            Text("Video not available")
                .font(theme.bodyFont)
                .foregroundColor(theme.text.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.secondary)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
    }
    
    // Reaction controls section
    private var reactionControls: some View {
        VStack(spacing: theme.spacing) {
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
            }
            
            if door.hasReacted(userId: userId) {
                Text("Thanks for spreading love!")
                    .font(theme.bodyFont)
                    .foregroundColor(theme.text.opacity(0.6))
            }
        }
        .padding(.top, theme.spacing)
    }
        
    // Sheet that appears when user wants to add a reaction
    private var reactionSheet: some View {
        VStack(spacing: theme.spacing) {
            Text("Choose a Reaction")
                .font(theme.titleFont.bold())
                .foregroundColor(theme.text)
                .padding(.top)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            
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

// MARK: - Controllers

// Represents a UIViewController wrapper around AVPlayerViewController
// This enables native iOS video playback with full controls including fullscreen support
struct VideoViewController: UIViewControllerRepresentable {
    let url: URL
    
    // Creates and configures the AVPlayerViewController
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let player = AVPlayer(url: url)
        controller.player = player
        controller.showsPlaybackControls = true
        return controller
    }
    
    // Required by UIViewControllerRepresentable but unused in our case
    // Called when the SwiftUI view updates
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
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
