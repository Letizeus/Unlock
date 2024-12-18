import Foundation

// Represents a complete holiday calendar with multiple doors
struct HolidayCalendar: Identifiable {
    let id = UUID()
    let title: String
    let startDate: Date
    let endDate: Date
    var doors: [CalendarDoor]
}

// Represents an individual door in the holiday calendar
struct CalendarDoor: Identifiable {
    let id = UUID()
    let number: Int
    let unlockDate: Date // Date when the door becomes unlockable
    var isUnlocked: Bool
    var content: DoorContent
}

// Defines different types of content that can be behind a door
enum DoorContent {
    case text(String)
    case image(String)
    case video(String)
    case map(latitude: Double, longitude: Double)
}

// Defines the available tabs in the main navigation
enum Tab {
    case calendar
    case map
    case editor
}
