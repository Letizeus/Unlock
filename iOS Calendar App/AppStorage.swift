import SwiftUI
import SwiftData

// Handles all data persistence operations for the app
class AppStorage {
    static let shared = AppStorage()
    
    private let fileManager = FileManager.default // Uses FileManager for file system operations
    
    // MARK: - Directory Management
    
    // Computes the URL for the app's documents directory
    // This is the primary location for storing user-generated content
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // Creates a dedicated directory for storing calendar files
    // Helps organize and separate calendar-related data from other app data
    private var calendarDirectory: URL {
        documentsDirectory.appendingPathComponent("Calendar", isDirectory: true)
    }
    
    // Creates a dedicated directory for storing media files associated with calendars
    // Ensures media files are managed separately from calendar metadata
    private var mediaDirectory: URL {
        documentsDirectory.appendingPathComponent("Media", isDirectory: true)
    }
    
    private init() {
        // Creates necessary directories if they don't exist
        try? fileManager.createDirectory(at: calendarDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: mediaDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Calendar Storage
    
    // Defines the file path for the current calendar's JSON representation
    // Uses a fixed filename to always represent the most recent calendar
    private var calendarURL: URL {
        calendarDirectory.appendingPathComponent("current_calendar.json")
    }
    
    // Saves the calendar
    func saveCalendar(_ calendar: HolidayCalendar) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(calendar)
        try data.write(to: calendarURL)
    }
    
    // Attempts to load a previously saved calendar from storage
    func loadCalendar() -> HolidayCalendar? {
        guard let data = try? Data(contentsOf: calendarURL) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(HolidayCalendar.self, from: data)
    }
    
    // MARK: - Editor Calendar Storage
    
    // Defines the file path for the current editor's JSON representation
    // Uses a fixed filename to always represent the most recent editor
    private var editorStateURL: URL {
        documentsDirectory.appendingPathComponent("editor_state.json")
    }
    
    // Saves the editor
    func saveEditorState(_ state: EditorModel) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(state)
        try data.write(to: editorStateURL)
    }
    
    // Attempts to load the previously saved editor state from storage
    func loadEditorState() -> EditorModel? {
        guard let data = try? Data(contentsOf: editorStateURL) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(EditorModel.self, from: data)
    }
    
    // MARK: - Media Storage
    
    // Saves media data with a unique identifier
    func saveMedia(data: Data, identifier: String) throws {
        let mediaURL = mediaDirectory.appendingPathComponent(identifier)
        try data.write(to: mediaURL)
    }
    
    // Retrieves media data for a given identifier
    func loadMedia(identifier: String) -> Data? {
        let mediaURL = mediaDirectory.appendingPathComponent(identifier)
        return try? Data(contentsOf: mediaURL)
    }
    
    // Deletes a specific media file
    // Useful for cleaning up unused or replaced media
    func deleteMedia(identifier: String) {
        let mediaURL = mediaDirectory.appendingPathComponent(identifier)
        try? fileManager.removeItem(at: mediaURL)
    }
    
    // Creates a temporary video file from the provided video data
    func createTemporaryVideoFile(with data: Data) -> URL? {
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory // Gets the temporary directory URL
        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent("\(UUID().uuidString).mp4") // Creates a unique filename for the temporary video file
        
        do {
            try data.write(to: temporaryFileURL) // Writes the video data to the temporary file
            return temporaryFileURL
        } catch {
            return nil
        }
    }
    
    // MARK: - Calendar Export/Import

    
    
    // MARK: - Cleanup
    
    // Removes media files that are no longer referenced by the current calendar
    // Helps prevent unnecessary storage consumption
    func cleanupUnusedMedia() {
        guard let calendar = loadCalendar() else { return }
        
        // Gets all media files in the media directory
        let mediaFiles = try? fileManager.contentsOfDirectory(at: mediaDirectory, includingPropertiesForKeys: nil)
        
        // Gets all media filenames currently in use by the calendar
        let usedFiles = Set(calendar.doors.compactMap { door -> String? in
            switch door.content {
            case .image(let filename), .video(let filename):
                return filename
            default:
                return nil
            }
        })
        
        // Deletes any media files not referenced by current calendar
        mediaFiles?.forEach { url in
            let filename = url.lastPathComponent
            if !usedFiles.contains(filename) {
                try? fileManager.removeItem(at: url)
            }
        }
    }
}
