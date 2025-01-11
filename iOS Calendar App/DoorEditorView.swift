import SwiftUI
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
        case .image(let path):
            if let image = UIImage(named: path) {
                _selectedImage = State(initialValue: image)
            }
        case .video(let url):
            _textContent = State(initialValue: url)
        case .map(_, _):
            _textContent = State(initialValue: "")
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
                        Text("Map").tag(DoorContent.map(latitude: 0, longitude: 0))
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
    
    // Section for editing the content based on selected type
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing) {
            Section("Content") {
                HStack {
                    switch contentType {
                    case .text:
                        textEditor
                    case .image:
                        imageSelector
                    default:
                        Text("Content type not implemented yet")
                            .font(theme.bodyFont)
                            .foregroundColor(theme.text.opacity(0.6))
                        Spacer()
                    }
                }
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
                let filename = "door_\(door.number)_\(UUID().uuidString).jpg" // Generates a unique filename for the image
                UserDefaults.standard.set(imageData, forKey: filename) // Saves image data using UserDefaults
                updatedDoor.content = .image(filename)
            }
        case .video(let url):
            updatedDoor.content = .video(url)
        case .map(let lat, let long):
            updatedDoor.content = .map(latitude: lat, longitude: long)
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
