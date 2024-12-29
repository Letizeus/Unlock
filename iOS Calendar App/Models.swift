import Foundation

// MARK: - HolidayCalendar
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
    case map(latitude: Double, longitude: Double)
    
    var contentType: String {
        switch self {
            case .text: return "Text"
            case .image: return "Image"
            case .video: return "Video"
            case .map: return "Map"
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

// MARK: - GridLayoutMode
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

// MARK: - UnlockMode
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

// MARK: - CountdownInfo
// Holds information for countdown display
struct CountdownInfo {
    var days: Int = 0
    var hours: Int = 0
    var minutes: Int = 0
}

// MARK: - Tab
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

// MARK: - CalendarError
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
