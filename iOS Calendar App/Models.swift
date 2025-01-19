import Foundation
import UIKit
import SwiftUICore

// MARK: - HolidayCalendar
// Represents a complete holiday calendar with multiple doors
struct HolidayCalendar: Identifiable, Codable {
    var id = UUID()
    var title: String
    var startDate: Date
    var endDate: Date
    var doors: [CalendarDoor]
    var gridColumns: Int
    var backgroundImageData: Data?
    var codableBackgroundColor: CodableColor?
    
    // Public interface for backgroundColor
    var backgroundColor: Color {
        get { codableBackgroundColor?.color ?? .clear }
        set { codableBackgroundColor = CodableColor(newValue) }
    }
    
    init(title: String, startDate: Date, endDate: Date, doors: [CalendarDoor], gridColumns: Int = 4, backgroundImageData: Data? = nil, backgroundColor: Color = .clear) {
        self.id = UUID()
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.doors = doors
        self.gridColumns = gridColumns
        self.backgroundImageData = backgroundImageData
        self.codableBackgroundColor = CodableColor(backgroundColor)
    }
    
    // Creates a sample holiday calendar for preview
    // Each door is configured with a unlock date and sample text content
    static func createDefault() -> HolidayCalendar {
        let dates = (1...Constants.Calendar.defaultDoorCount).map { day -> Date in
            let components = DateComponents(
                year: Constants.Calendar.defaultYear,
                month: Constants.Calendar.defaultMonth,
                day: day,
                hour: 0,
                minute: 0,
                second: 0
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
            title: "Empty Calendar",
            startDate: dates.first ?? Date(),
            endDate: dates.last ?? Date(),
            doors: doors,
            gridColumns: Constants.Calendar.defaultGridColumns
        )
    }
    
    // Creates a copy of the calendar
    func copy() -> HolidayCalendar {
        HolidayCalendar(
            title: self.title,
            startDate: self.startDate,
            endDate: self.endDate,
            doors: self.doors,
            gridColumns: self.gridColumns,
            backgroundImageData: self.backgroundImageData,
            backgroundColor: self.backgroundColor
        )
    }
}

// MARK: - CalendarDoor
// Represents an individual door in the holiday calendar
struct CalendarDoor: Identifiable, Codable {
    var id = UUID()
    let number: Int
    var unlockDate: Date // Date when the door becomes unlockable
    var isUnlocked: Bool
    var content: DoorContent
    var hasBeenOpened: Bool
    var reactions: [Reaction] // Array of reactions that users have added to this door
        
    init(number: Int, unlockDate: Date, isUnlocked: Bool, content: DoorContent, hasBeenOpened: Bool) {
        self.id = UUID()
        self.number = number
        self.unlockDate = unlockDate
        self.isUnlocked = isUnlocked
        self.content = content
        self.hasBeenOpened = false
        self.reactions = []
    }
    
    // Updates the door's unlock state based on the current date
    mutating func updateUnlockState() {
        isUnlocked = Date() >= unlockDate
    }
    
    // Adds a new reaction to the door
    mutating func addReaction(_ emoji: String, userId: String) {
        let reaction = Reaction(emoji: emoji, userId: userId)
        reactions.append(reaction)
    }
    
    // Checks if a specific user has already reacted to this door
    func hasReacted(userId: String) -> Bool {
        reactions.contains { $0.userId == userId }
    }
    
    // Counts how many times each emoji has been used as a reaction
    func reactionCounts() -> [String: Int] {
        var counts: [String: Int] = [:]
        for reaction in reactions {
            counts[reaction.emoji, default: 0] += 1
        }
        return counts
    }
}

// MARK: - DoorContent
// Defines different types of content that can be behind a door
enum DoorContent: Codable, Hashable {
    case text(String)
    case image(String)
    case video(String)
    
    var contentType: String {
        switch self {
            case .text: return "Text"
            case .image: return "Image"
            case .video: return "Video"
        }
    }
}

// MARK: - Reaction
// Represents a single reaction to a calendar door
// Stores information about who made the reaction and when
struct Reaction: Identifiable, Codable {
    let id: UUID
    let emoji: String
    let userId: String // Uses device ID for simplicity, but could be expanded to use actual user IDs
    let timestamp: Date // When the reaction was created
    
    init(emoji: String, userId: String) {
        self.id = UUID()
        self.emoji = emoji
        self.userId = userId
        self.timestamp = Date()
    }
}

// MARK: - EditorModel
// Represents the state and configuration of the calendar editor interface
struct EditorModel: Codable {
    var calendarTitle: String = ""
    var startDate: Date = Date()
    var endDate: Date = Date().addingTimeInterval(24 * 60 * 60 * 31)
    var doorCount: Int = Constants.Calendar.defaultDoorCount
    var gridColumns: Int = Constants.Calendar.defaultGridColumns // Controls how many doors appear in each row of the calendar view
    var unlockMode: UnlockMode = .daily
    var backgroundType: BackgroundType = .image
    var doors: [CalendarDoor] = []
    var backgroundImageData: Data?
    var codableBackgroundColor: CodableColor?
    
    // Public interface for backgroundColor
    var backgroundColor: Color {
        get { codableBackgroundColor?.color ?? .clear }
        set { codableBackgroundColor = CodableColor(newValue) }
    }
    
    // Creates a HolidayCalendar instance from the current editor state
    // This is used when saving or previewing the calendar
    func createCalendar() -> HolidayCalendar {
        let currentDate = Calendar.current.startOfDay(for: Date())
        // Creates doors with proper unlock states
        let updatedDoors = doors.map { door in
            var updatedDoor = door
            updatedDoor.isUnlocked = Calendar.current.startOfDay(for: door.unlockDate) <= currentDate
            return updatedDoor
        }
        
        return HolidayCalendar(
            title: calendarTitle.isEmpty ? "Preview Calendar" : calendarTitle,
            startDate: startDate,
            endDate: endDate,
            doors: updatedDoors,
            gridColumns: gridColumns,
            backgroundImageData: backgroundImageData,
            backgroundColor: backgroundColor
        )
    }
}

// MARK: - CalendarBundle
// Creates a bundle structure to include media files
struct CalendarBundle: Codable {
    var calendar: HolidayCalendar
    var mediaFiles: [String: Data]  // filename -> file data
}

// MARK: - UnlockMode
// Defines how doors in the calendar should unlock
enum UnlockMode: Codable {
    case daily     // Doors unlock one per day
    case specific  // Each door has a specific unlock date
    
    var description: String {
        switch self {
            case .daily: return "Daily"
            case .specific: return "Specific Dates"
        }
    }
}

// MARK: - BackgroundType
// Defines the different types of backgrounds that can be used in a calendar
enum BackgroundType: Codable {
    case color
    case image
}

// MARK: - CountdownInfo
// Holds information for countdown display
struct CountdownInfo {
    var days: Int = 0
    var hours: Int = 0
    var minutes: Int = 0
}

// MARK: - Tab
// Defines the available tabs in the main navigation
enum Tab: String {
    case calendar
    case map
    case editor
    
    var title: String {
        switch self {
            case .calendar: return "Calendar"
            case .map: return "Map"
            case .editor: return "Editor"
        }
    }
    
    var icon: String {
        switch self {
            case .calendar: return "calendar"
            case .map: return "map"
            case .editor: return "pencil"
        }
    }
}

// MARK: - OnboardingStep
// Represents the different steps in the onboarding flow
// Controls which view is displayed to the user during onboarding
enum OnboardingStep {
    case welcome
    case home
}

// MARK: - CodableColor
// Wraps a Color and makes it codable
struct CodableColor: Codable {
    let color: Color
    
    init(_ color: Color) {
        self.color = color
    }
    
    // Enum defining the coding keys for encoding/decoding
    private enum CodingKeys: String, CodingKey {
        case red, green, blue, alpha
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = try container.decode(Double.self, forKey: .red)
        let green = try container.decode(Double.self, forKey: .green)
        let blue = try container.decode(Double.self, forKey: .blue)
        let alpha = try container.decode(Double.self, forKey: .alpha)
        
        self.color = Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
    
    // Method for encoding a CodableColor to JSON
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Converts the Color to a UIColor to access its RGBA components
        let uiColor = UIColor(self.color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Encodes the RGBA values as Double
        try container.encode(Double(red), forKey: .red)
        try container.encode(Double(green), forKey: .green)
        try container.encode(Double(blue), forKey: .blue)
        try container.encode(Double(alpha), forKey: .alpha)
    }
}
