import SwiftUI

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
}
