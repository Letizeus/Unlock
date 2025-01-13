import SwiftUI
import UniformTypeIdentifiers

// Manages the global state of the calendar editor throughout the application lifecycle
class EditorStateManager: ObservableObject {
    static let shared = EditorStateManager()
    
    // The current state of the editor
    @Published var model: EditorModel {
        didSet {
            save() // Saves editor data whenever it changes
        }
    }
    
    // Loads saved state if available, otherwise creates default state
    private init() {
        if let savedModel = AppStorage.shared.loadEditorState() {
            self.model = savedModel
        } else {
            self.model = EditorModel()
        }
    }
    
    // Saves the current editor state to storage
    // Called automatically when model changes
    private func save() {
        try? AppStorage.shared.saveEditorState(model)
    }
    
    // Resets the editor state to default values
    func reset() {
        model = EditorModel()
        save()
    }
    
    // MARK: - Storage Operations
    
    // Exports the current calendar data
    func exportCalendar() throws {
        let calendar = model.createCalendar() // Creates a calendar instance from the current editor model
        
        let (exportData, filename) = try AppStorage.shared.exportCalendar(calendar) // Gets export data and generated filename from AppStorage
        
        // Creates a temporary file URL
        let tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try exportData.write(to: tempFileURL)
        
        // Retrieves the current window scene and root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            // Creates activity view controller for sharing the exported file
            let activityViewController = UIActivityViewController(
                activityItems: [tempFileURL],
                applicationActivities: nil
            )
            
            // Cleans up the temporary file after sharing
            activityViewController.completionWithItemsHandler = { _, _, _, _ in
                try? FileManager.default.removeItem(at: tempFileURL)
            }
            
            rootViewController.present(activityViewController, animated: true) // Presents the activity view controller
        }
    }
}

// MARK: - Extensions

// This extension on the UTType struct defines a custom Uniform Type Identifier (UTI) for holiday calendar files.
extension UTType {
    static var holidayCalendar: UTType {
        UTType(exportedAs: "com.holiday.calendar")
    }
}
