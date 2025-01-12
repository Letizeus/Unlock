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
    
    // Saves a calendar
    func saveCalendar(_ calendar: HolidayCalendar) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(calendar)
        try data.write(to: calendarURL)
    }
    
    // Attempts to load a previously saved calendar
    func loadCalendar() -> HolidayCalendar? {
        guard let data = try? Data(contentsOf: calendarURL) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(HolidayCalendar.self, from: data)
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
    
    // Prepares a calendar for export by bundling media files
    // Creates a new version of the calendar with embedded media data
    func exportCalendar(_ calendar: HolidayCalendar) throws -> Data {
        // When exporting, we need to include media files
        var exportCalendar = calendar
        
        // Bundles media files with the calendar
        for (index, door) in calendar.doors.enumerated() {
            switch door.content {
            case .image(let filename), .video(let filename):
                if let mediaData = loadMedia(identifier: filename) {
                    // Embeds the media data directly in the export
                    let newFilename = "export_\(door.id.uuidString)_\(filename)"
                    try saveMedia(data: mediaData, identifier: newFilename)
                    
                    // Updates the door's content to use the new filename
                    switch door.content {
                    case .image:
                        exportCalendar.doors[index].content = .image(newFilename)
                    case .video:
                        exportCalendar.doors[index].content = .video(newFilename)
                    default:
                        break
                    }
                }
            default:
                break
            }
        }
        
        let encoder = JSONEncoder()
        return try encoder.encode(exportCalendar)
    }
    
    // Imports a calendar from exported data
    func importCalendar(from data: Data) throws -> HolidayCalendar {
        let decoder = JSONDecoder()
        let calendar = try decoder.decode(HolidayCalendar.self, from: data)
        
        // Process and save any media files that came with the calendar
        for door in calendar.doors {
            switch door.content {
            case .image(let filename), .video(let filename):
                if let mediaData = loadMedia(identifier: filename) {
                    let newFilename = "import_\(door.id.uuidString)_\(filename)"
                    try saveMedia(data: mediaData, identifier: newFilename)
                }
            default:
                break
            }
        }
        
        return calendar
    }
    
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
