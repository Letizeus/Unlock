import Foundation

// Represents a complete holiday calendar with multiple doors
struct HolidayCalendar: Identifiable, Codable {
    var id = UUID()
    let title: String
    let startDate: Date
    let endDate: Date
    var doors: [CalendarDoor]
    
    init(title: String, startDate: Date, endDate: Date, doors: [CalendarDoor]) {
        self.id = UUID()
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.doors = doors
    }
    
    // Creates a sample holiday calendar for preview
    // Each door is configured with a unlock date and sample text content
    static func createDefault() -> HolidayCalendar {
        let dates = (1...Constants.Calendar.doorCount).map { day -> Date in
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
            doors: doors
        )
    }
}

// Represents an individual door in the holiday calendar
struct CalendarDoor: Identifiable, Codable {
    var id = UUID()
    let number: Int
    let unlockDate: Date // Date when the door becomes unlockable
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
enum DoorContent: Codable {
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

struct CountdownInfo {
    var days: Int = 0
    var hours: Int = 0
    var minutes: Int = 0
}

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
