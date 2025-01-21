import SwiftUI
import AVKit
import PhotosUI

struct DoorEditorView: View {
    
    @Environment(\.editorTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    
    let door: CalendarDoor // The door being edited
    let onSaveDoor: (CalendarDoor) -> Void // Callback function called when changes are saved
    let unlockMode: UnlockMode
    
    @State private var contentType: DoorContent // The current type of content being edited

    @State private var textContent = "" // Text content when content type is .text
    // Selected image for image content type
    @State private var selectedImage: UIImage?
    @State private var selectedImageItem: PhotosPickerItem?
    // Selected video for video content type
    @State private var selectedVideo: Data?
    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var videoPlayer: AVPlayer?
    @State private var isLoadingVideo = false
    @State private var isVideoPreviewReady = false
    
    // Date management
    @State private var unlockDate: Date
    @State private var useCustomUnlockDate: Bool
    
    // MARK: - Initialization
    
    init(door: CalendarDoor, unlockMode: UnlockMode, onSaveDoor: @escaping (CalendarDoor) -> Void) {
        self.door = door
        self.unlockMode = unlockMode
        self.onSaveDoor = onSaveDoor
        
        _contentType = State(initialValue: door.content)
        
        _unlockDate = State(initialValue: door.unlockDate)
        _useCustomUnlockDate = State(initialValue: unlockMode == .specific)
        
        // Initialize content based on type
        switch door.content {
            case .text(let text):
                _textContent = State(initialValue: text)
            case .image(let filename):
                if let imageData = AppData.shared.loadMedia(identifier: filename),
                   let image = UIImage(data: imageData) {
                    _selectedImage = State(initialValue: image)
                } else {
                    _selectedImage = State(initialValue: nil)
                }
            case .video(let filename):
                if let videoData = AppData.shared.loadMedia(identifier: filename) {
                    _selectedVideo = State(initialValue: videoData)
                    let temporaryFileURL = AppData.shared.createTemporaryVideoFile(with: videoData)
                    if let videoURL = temporaryFileURL {
                        _videoPlayer = State(initialValue: AVPlayer(url: videoURL))
                        _isVideoPreviewReady = State(initialValue: true)
                    } else {
                        _videoPlayer = State(initialValue: nil)
                        _isVideoPreviewReady = State(initialValue: false)
                    }
                } else {
                    _selectedVideo = State(initialValue: nil)
                    _videoPlayer = State(initialValue: nil)
                    _isVideoPreviewReady = State(initialValue: false)
                }
        }
    }
    
    // MARK: - View Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing) {
                    // Only show unlock date section if in specific unlock mode
                    if unlockMode == .specific {
                        unlockDateSection
                    }
                    contentTypeSection
                    contentSection
                    markdownSection
                }
                .padding(theme.padding)
            }
            .background(theme.background)
            .navigationTitle("Edit Door \(door.number)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
        }
    }
    
    // MARK: - UI Components
    
    // Section for configuring the door's unlock date
    private var unlockDateSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing) {
            Section {
                DatePicker(
                    "Unlock Date",
                    selection: $unlockDate,
                    displayedComponents: .date
                )
                .font(theme.bodyFont)
            } header: {
                Text("Unlock Date")
                    .font(theme.headlineFont)
                    .foregroundColor(theme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .listRowBackground(theme.secondary)
        }
        .padding(theme.padding)
        .background(theme.secondary)
        .cornerRadius(theme.cornerRadius)
    }
    
    // Section for selecting the content type
    private var contentTypeSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing) {
            Section {
                HStack {
                    Text("Type")
                        .foregroundColor(theme.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Spacer() // This pushes the picker to the right
                    Picker("", selection: $contentType) {
                        Text("Text").tag(DoorContent.text(textContent))
                        Text("Image").tag(DoorContent.image(""))
                        Text("Video").tag(DoorContent.video(""))
                    }
                    .font(theme.bodyFont)
                }
            } header: {
                Text("Content Type")
                    .font(theme.headlineFont)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .listRowBackground(theme.secondary)
        }
        .padding(theme.padding)
        .background(theme.secondary)
        .cornerRadius(theme.cornerRadius)
    }
    
    // Section for handy markdown information
    private var markdownSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing) {
            Section {
                VStack {
                    HStack(alignment: .top) {
                        Text("*Italic*")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(verbatim: "*italic text*")
                    }
                    Divider()
                    HStack(alignment: .top) {
                        Text("**Bold**")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(verbatim: "**bold text**")
                    }
                    Divider()
                    HStack(alignment: .top) {
                        Text("`code`")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(verbatim: "`code`")
                    }
                }
                
            } header: {
                Text("Markdown information")
                    .font(theme.headlineFont)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .padding(theme.padding)
        .background(theme.secondary)
        .cornerRadius(theme.cornerRadius)
    }
    
    // Section for editing the content based on selected type
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing) {
            Section() {
                HStack {
                    switch contentType {
                    case .text:
                        textEditor
                    case .image:
                        imageSelector
                    case .video:
                        videoSelector
                    }
                }
            } header: {
                Text("Content")
                    .font(theme.headlineFont)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .padding(theme.padding)
        .background(theme.secondary)
        .cornerRadius(theme.cornerRadius)
    }
    
    // Text editor for text content type
    private var textEditor: some View {
        TextEditor(text: $textContent)
            .frame(height: 200)
            .font(theme.bodyFont)
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .cornerRadius(theme.cornerRadius)
            .onChange(of: textContent) { _, newValue in
                contentType = .text(newValue)
            }
    }
    
    // Image selector for image content type
    private var imageSelector: some View {
        PhotosPicker(selection: $selectedImageItem, matching: .images) {
            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: theme.imagePickerStyle.previewHeight)
                    .cornerRadius(theme.cornerRadius)
            } else {
                Label("Select Image", systemImage: "photo")
                    .font(theme.bodyFont)
                    .frame(maxWidth: .infinity)
                    .frame(height: theme.imagePickerStyle.previewHeight / 2)
                    .background(theme.imagePickerStyle.placeholderColor)
                    .cornerRadius(theme.cornerRadius)
            }
        }
        .background(theme.secondary)
        .cornerRadius(theme.cornerRadius)
        .onChange(of: selectedImageItem) { _, _ in
            Task {
                // Try to load the selected image as transferable data
                if let data = try? await selectedImageItem?.loadTransferable(type: Data.self) {
                    selectedImage = UIImage(data: data) // Convert the raw data into a UIImage if possible
                }
            }
        }
    }
    
    // Video selector view for video content type
    private var videoSelector: some View {
        PhotosPicker(selection: $selectedVideoItem, matching: .videos) {
            if isLoadingVideo {
                // If the video is currently loading, show a loading indicator
                VStack {
                    ProgressView()
                        .padding(.bottom, 4)
                    Text("Loading Video...")
                        .font(theme.bodyFont)
                }
                .frame(maxWidth: .infinity)
                .frame(height: theme.imagePickerStyle.previewHeight)
                .background(theme.imagePickerStyle.placeholderColor)
                .cornerRadius(theme.cornerRadius)
            } else if let player = videoPlayer, isVideoPreviewReady {
                // If the video player is available and the preview is ready, show the video player
                VideoPlayer(player: player)
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(theme.cornerRadius)
            } else {
                // If no video is selected or the preview is not ready, show a placeholder view
                Label("Select Video", systemImage: "video")
                    .font(theme.bodyFont)
                    .frame(maxWidth: .infinity)
                    .frame(height: theme.imagePickerStyle.previewHeight)
                    .background(theme.imagePickerStyle.placeholderColor)
                    .cornerRadius(theme.cornerRadius)
            }
        }
        .onChange(of: selectedVideoItem) { _, _ in
            Task {
                isLoadingVideo = true
                isVideoPreviewReady = false
                videoPlayer?.pause()
                videoPlayer = nil
                
                // Tries to load the selected video as transferable data
                if let data = try? await selectedVideoItem?.loadTransferable(type: Data.self) {
                    selectedVideo = data
                    
                    // Creates temporary file for preview
                    let temporaryFileURL = AppData.shared.createTemporaryVideoFile(with: data)
                    if let videoURL = temporaryFileURL {
                        let player = AVPlayer(url: videoURL)
                        videoPlayer = player
                        isVideoPreviewReady = true
                    }
                }
                isLoadingVideo = false
            }
        }
        .onDisappear {
            videoPlayer?.pause()
            videoPlayer = nil
        }
    }
    
    // Toolbar items for navigation and saving
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(theme.accent)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChanges()
                }
                .foregroundColor(theme.accent)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    // Saves the current changes to the door
    private func saveChanges() {
        var updatedDoor = door
        
        // Updates content based on type
        switch contentType {
            case .text:
                updatedDoor.content = .text(textContent)
            case .image:
                if let image = selectedImage,
                    let imageData = image.jpegData(compressionQuality: 1) {
                    let filename = "door_\(door.number)_image_\(UUID().uuidString)" // Generates a unique filename for the image
                    try? AppData.shared.saveMedia(data: imageData, identifier: filename)
                    updatedDoor.content = .image(filename)
                }
            case .video:
                if let videoData = selectedVideo {
                    let filename = "door_\(door.number)_video_\(UUID().uuidString)" // Generates a unique filename for the video
                    try? AppData.shared.saveMedia(data: videoData, identifier: filename)
                    updatedDoor.content = .video(filename)
                }
        }
        
        // Only update unlock date if in specific mode
        if unlockMode == .specific {
            updatedDoor.unlockDate = unlockDate
        }
        
        onSaveDoor(updatedDoor)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DoorEditorView(
            door: CalendarDoor(
                number: 1,
                unlockDate: Date(),
                isUnlocked: false,
                content: .text("Sample text"),
                hasBeenOpened: false
            ),
            unlockMode: .specific,
            onSaveDoor: { _ in }
        )
        .environment(\.editorTheme, EditorTheme.default)
    }
}
