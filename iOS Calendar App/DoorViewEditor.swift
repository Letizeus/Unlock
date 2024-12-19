import SwiftUI
import PhotosUI

struct DoorViewEditor: View {
    
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
        
        // Set initial text content if door contains text
        switch door.content {
        case .text(let text):
            _textContent = State(initialValue: text)
        default:
            break
        }
    }
    
    // MARK: - View Body
    
    var body: some View {
        Form {
            // Only show unlock date section if in specific unlock mode
            if unlockMode == .specific {
                unlockDateSection
            }
            contentTypeSection
            contentSection
        }
        .navigationTitle("Edit Door \(door.number)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
    }
    
    // MARK: - UI Components
    
    // Section for configuring the door's unlock date
    private var unlockDateSection: some View {
        Section("Unlock Date") {
            DatePicker(
                "Unlock Date",
                selection: $unlockDate,
                displayedComponents: .date
            )
        }
    }
    
    // Section for selecting the content type
    private var contentTypeSection: some View {
        Section("Content Type") {
            Picker("Type", selection: $contentType) {
                Text("Text").tag(DoorContent.text(""))
                Text("Image").tag(DoorContent.image(""))
                Text("Video").tag(DoorContent.video(""))
                Text("Location").tag(DoorContent.map(latitude: 0, longitude: 0))
            }
        }
    }
    
    // Section for editing the content based on selected type
    private var contentSection: some View {
        Section("Content") {
            switch contentType {
            case .text:
                textEditor
            case .image:
                imageSelector
            default:
                Text("Content type not implemented yet")
            }
        }
    }
    
    // Text editor for text content type
    private var textEditor: some View {
        TextEditor(text: $textContent)
            .frame(height: 200)
    }
    
    // Image selector for image content type
    private var imageSelector: some View {
        PhotosPicker(selection: $selectedImageItem, matching: .images) {
            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
            } else {
                Label("Select Image", systemImage: "photo")
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
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
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChanges()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Saves the current changes to the door
    private func saveChanges() {
        var updatedDoor = door
        updatedDoor.content = contentType
        // Only update unlock date if in specific mode
        if unlockMode == .specific {
            updatedDoor.unlockDate = unlockDate
        }
        onSaveDoor(updatedDoor)
        dismiss()
    }
}
