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
    
    @State private var isLoadingVideo = false // Indicates if a video is currently loading
    @State private var isFullscreen = false // Indicates if an image is currently in full-screen
    
    // States for tracking share sheet presentation
    @State private var isShareSheetPresented = false
    @State private var shareItems: [Any] = []
    
    // Generate a simple device ID (only a temp solution)
    private let userId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    
    // MARK: - View Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing) {
                    banner
                        .padding(.horizontal, theme.padding.leading)
                    
                    // Display selected reaction at the top if one exists
                    if !door.reactions.isEmpty {
                        reactionCountsView
                            .padding(.horizontal, theme.padding.leading)
                    }
                    
                    // Main content
                    contentView
                    
                    reactionControls
                        .padding(.horizontal, theme.padding.leading)
                    
                    Spacer(minLength: theme.spacing)
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Leading: Share Button
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        shareContent()
                    } label: {
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
            
            Text("Door \(door.number)")
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
                // Loads image from AppData
                if let imageData = AppData.shared.loadMedia(identifier: filename),
                   let uiImage = UIImage(data: imageData) {
                    imageContent(uiImage: uiImage)
                } else {
                    missingImageContent
                }
            case .video(let filename):
                // Loads video from AppData
                if let videoData = AppData.shared.loadMedia(identifier: filename) {
                    videoContent(videoData: videoData)
                } else {
                    missingVideoContent
                }
            }
        }
    }
    
    // Displays text content
    private func textContent(_ text: String) -> some View {
        // Convert String to attributed string
        
        var attrString: AttributedString = ""
        
        do {
            // Using special markdown parsing options, so \n e.g. works in the attributed string
            attrString = try AttributedString(markdown: text, options: AttributedString.MarkdownParsingOptions(interpretedSyntax:
                    .inlineOnlyPreservingWhitespace))
        } catch {
            // Catch error when converting fails
            print("Failed to create attributed String")
        }
        
        return VStack(spacing: theme.spacing) {
            Text(attrString)
                .foregroundColor(theme.text)
                .multilineTextAlignment(.leading)
                .padding(theme.padding)
                .frame(maxWidth: .infinity)
                .background(theme.secondary)
                .cornerRadius(theme.cornerRadius)
                .padding(.horizontal, theme.padding.leading)
        }
        
    }
    
    // Displays image content
    private func imageContent(uiImage: UIImage) -> some View {
        GeometryReader { geo in
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: geo.size.width)
                .cornerRadius(theme.cornerRadius)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .onTapGesture {
                    isFullscreen = true
                }
        }
        .padding(.horizontal, theme.padding.leading)
        .frame(height: (UIScreen.main.bounds.width - (theme.padding.leading + theme.padding.trailing)) * uiImage.size.height / uiImage.size.width)
        .fullScreenCover(isPresented: $isFullscreen) {
            ZoomableImageView(image: uiImage) {
                isFullscreen = false
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
                    .frame(width: geo.size.width, height: geo.size.width * 9/16)
                    .background(theme.secondary)
                    .cornerRadius(theme.cornerRadius)
                } else {
                    // Creates a temporary file URL for the video data
                    let temporaryFileURL = AppData.shared.createTemporaryVideoFile(with: videoData, doorNumber: 0)
                    
                    // If the temporary file URL is successfully created, display the video player
                    if let videoURL = temporaryFileURL {
                        VideoViewController(url: videoURL)
                            .frame(width: geo.size.width, height: geo.size.width * 9/16)
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
        .padding(.horizontal, theme.padding.leading)
        .frame(height: (UIScreen.main.bounds.width - (theme.padding.leading + theme.padding.trailing)) * 9/16)
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
                Text("Thanks for reacting!")
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
    
    // MARK: - Helper Functions
    
    // Prepares and presents a system share sheet for the door's content
    private func shareContent() {
        var itemsToShare: [Any] = [] // Array to collect all items that will be shared
        
        // Handles different types of door content
        switch content {
        case .text(let text):
            if let temporaryURL = AppData.shared.createTemporaryTextFile(text, doorNumber: door.number) {
                itemsToShare.append(temporaryURL)
            }
            
        case .image(let filename):
            if let imageData = AppData.shared.loadMedia(identifier: filename),
               let uiImage = UIImage(data: imageData) {
                if let temporaryFileURL = AppData.shared.createTemporaryImageFile(uiImage, doorNumber: door.number) {
                    itemsToShare.append(temporaryFileURL)
                }
            }
            
        case .video(let filename):
            if let videoData = AppData.shared.loadMedia(identifier: filename),
               let temporaryFileURL = AppData.shared.createTemporaryVideoFile(with: videoData, doorNumber: door.number) {
                itemsToShare.append(temporaryFileURL)
            }
        }
        
        guard !itemsToShare.isEmpty else { return } // Only proceed if we have items to share
        
        // Creates the system share sheet
        let activityVC = UIActivityViewController(
            activityItems: itemsToShare,
            applicationActivities: nil
        )
        
        // Gets access to the app's window and root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        // Finds the topmost presented view controller
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        
        topController.present(activityVC, animated: true) // Presents the share sheet
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

// MARK: - ZoomableImageView

// Displays a fullscreen image viewer with zoom functionality
struct ZoomableImageView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let image: UIImage
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ZoomableScrollView(image: image)
        }
        .overlay(alignment: .topTrailing) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    onDismiss()
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .frame(width: 28, height: 28)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .padding(.top, 46)
            .padding(.trailing, 12)
        }
        .edgesIgnoringSafeArea(.all)
        .statusBar(hidden: true)
    }
}

// UIViewRepresentable wrapper for UIScrollView with zooming
struct ZoomableScrollView: UIViewRepresentable {
    let image: UIImage
    
    // Creates and configures the UIScrollView with proper zoom settings
    func makeUIView(context: Context) -> UIScrollView {
        // Set up scroll view
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 3.0
        scrollView.minimumZoomScale = 1.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.decelerationRate = .fast
        
        // Set up image view
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)
        
        // Configure auto layout constraints to center the image
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            imageView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor)
        ])
        
        // Adds double tap gesture
        let doubleTapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGesture)
        
        return scrollView
    }
    func updateUIView(_ uiView: UIScrollView, context: Context) {}  // Required by UIViewRepresentable but unused in this implementation
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Handles UIScrollView delegate methods and gesture recognition
    class Coordinator: NSObject, UIScrollViewDelegate {
        let parent: ZoomableScrollView
        
        init(_ parent: ZoomableScrollView) {
            self.parent = parent
        }
        
        // Tells the scroll view which view to zoom (the image view)
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            scrollView.subviews.first as? UIImageView
        }
        
        // Handles double tap gesture to zoom in/out
        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = gesture.view as? UIScrollView else { return }
            
            if scrollView.zoomScale > scrollView.minimumZoomScale {
                // If zoomed in, zoom out to minimum scale
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            } else {
                // If zoomed out, zoom in on tap location
                let point = gesture.location(in: scrollView)
                let size = scrollView.bounds.size
                
                let width = size.width / scrollView.maximumZoomScale
                let height = size.height / scrollView.maximumZoomScale
                let rect = CGRect(x: point.x - width/2, y: point.y - height/2, width: width, height: height)
                
                scrollView.zoom(to: rect, animated: true)
            }
        }
        
        // Keeps the image centered while zooming
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            guard let imageView = scrollView.subviews.first else { return }

            let offsetX = max((scrollView.bounds.width - imageView.frame.width) * 0.5, 0)
            let offsetY = max((scrollView.bounds.height - imageView.frame.height) * 0.5, 0)
            
            imageView.center = CGPoint(x: imageView.frame.width * 0.5 + offsetX,
                                       y: imageView.frame.height * 0.5 + offsetY)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DoorContentView(
            content: .text("✨ **Lorem ipsum dolor sit amet**!✨ \n\nConsectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. 🌟"),
            door: CalendarDoor(
                number: 1,
                unlockDate: Date(),
                isUnlocked: true,
                content: .text("✨ **Lorem ipsum dolor sit amet**! \n\n✨Consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. 🌟"),
                hasBeenOpened: true
            ),
            onReactionAdded: { _ in }
        )
        .environment(\.calendarTheme, CalendarTheme.default)
    }
}
