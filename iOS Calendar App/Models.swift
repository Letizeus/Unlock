import Foundation

// Represents a complete holiday calendar with multiple doors
struct HolidayCalendar: Identifiable, Codable {
    var id = UUID()
    var title: String
    let startDate: Date
    let endDate: Date
    var doors: [CalendarDoor]
    var gridColumns: Int
    var backgroundImageData: Data?
    
    init(title: String, startDate: Date, endDate: Date, doors: [CalendarDoor], gridColumns: Int = 4, backgroundImageData: Data? = nil) {
        self.id = UUID()
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.doors = doors
        self.gridColumns = gridColumns
        self.backgroundImageData = backgroundImageData
    }
    
    // Creates a sample holiday calendar for preview
    // Each door is configured with a unlock date and sample text content
    static func createDefault() -> HolidayCalendar {
        let dates = (1...Constants.Calendar.defaultDoorCount).map { day -> Date in
            let components = DateComponents(
                year: Constants.Calendar.defaultYear,
                month: Constants.Calendar.defaultMonth,
                day: day
            )
            return Calendar.current.date(from: components) ?? Date()
        }
        
        let doors = dates.enumerated().map { (index, date) in
            CalendarDoor(
                number: index + 1,
                unlockDate: date,
                isUnlocked: date < Date(),
                content: .text("Content for door \(index + 1)"),
                hasBeenOpened: false
            )
        }
        
        return HolidayCalendar(
            title: "Calendar \(Constants.Calendar.defaultYear)",
            startDate: dates.first ?? Date(),
            endDate: dates.last ?? Date(),
            doors: doors,
            gridColumns: Constants.Calendar.defaultGridColumns
        )
    }
}

// Represents an individual door in the holiday calendar
struct CalendarDoor: Identifiable, Codable {
    var id = UUID()
    let number: Int
    var unlockDate: Date // Date when the door becomes unlockable
    var isUnlocked: Bool
    var content: DoorContent
    var hasBeenOpened: Bool
        
    init(number: Int, unlockDate: Date, isUnlocked: Bool, content: DoorContent, hasBeenOpened: Bool) {
        self.id = UUID()
        self.number = number
        self.unlockDate = unlockDate
        self.isUnlocked = isUnlocked
        self.content = content
        self.hasBeenOpened = false
    }
}

// Defines different types of content that can be behind a door
enum DoorContent: Codable, Hashable {
    case text(String)
    case image(String)
    case video(String)
    case map(latitude: Double, longitude: Double)
    
    var contentType: String {
        switch self {
            case .text: return "Text"
            case .image: return "Image"
            case .video: return "Video"
            case .map: return "Location"
        }
    }
}

enum GridLayoutMode: String, CaseIterable, Codable {
    case uniform = "Uniform"
    case random = "Different Sizes"
    
    var description: String {
        switch self {
            case .uniform: return "Uniform"
            case .random: return "Different Sizes"
        }
    }
}

// Defines the available tabs in the main navigation
enum Tab {
    case calendar
    case map
    case editor
    
    var title: String {
        switch self {
            case .calendar: return "Home"
            case .map: return "Map"
            case .editor: return "Editor"
        }
    }
    
    var icon: String {
        switch self {
            case .calendar: return "house.fill"
            case .map: return "map"
            case .editor: return "pencil"
        }
    }
}

// Defines how doors in the calendar should unlock
enum UnlockMode {
    case daily     // Doors unlock one per day
    case specific  // Each door has a specific unlock date
    
    var description: String {
        switch self {
            case .daily: return "Daily"
            case .specific: return "Specific Dates"
        }
    }
}

// Holds information for countdown display
struct CountdownInfo {
    var days: Int = 0
    var hours: Int = 0
    var minutes: Int = 0
}

// Defines possible errors that can occur during calendar operations
enum CalendarError: LocalizedError {
    case invalidDate
    case invalidContent
    case exportFailed
    case importFailed
    
    var errorDescription: String? {
        switch self {
            case .invalidDate: return "Invalid date provided"
            case .invalidContent: return "Invalid content format"
            case .exportFailed: return "Failed to export calendar"
            case .importFailed: return "Failed to import calendar"
        }
    }
}
