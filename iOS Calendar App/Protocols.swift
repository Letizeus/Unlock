import SwiftUI
import Foundation

// MARK: - Theme Protocols

// Protocol for defining theme properties
protocol ViewTheme {
    var spacing: CGFloat { get }
    var cornerRadius: CGFloat { get }
    var padding: EdgeInsets { get }
}

protocol Typography {
    var titleFont: Font { get }
    var subtitleFont: Font { get }
    var bodyFont: Font { get }
    var headlineFont: Font { get }
    var footnoteFont: Font { get }
    var captionFont: Font { get }
}

protocol ColorPalette {
    var primary: Color { get }
    var secondary: Color { get }
    var background: Color { get }
    var text: Color { get }
    var accent: Color { get }
}

// MARK: - Calendar Protocols

// Protocol defining the required properties and methods for door interaction behavior
// This ensures consistent behavior across different door view implementations
protocol DoorInteraction {
    var door: CalendarDoor { get set }
    var isAnyDoorOpening: Bool { get }
    var isShowingContent: Bool { get set }
    var doorRotation: Double { get set }
    var doorOpacity: Double { get set }
    var isPressed: Bool { get set }
    func handleDoorTap()
    func updateUnlockState()
}

// MARK: - Settings Protocols (UNUSED)

// Protocol defining the core functionality for managing calendar content
// Implementers of this protocol can save, load, export, and import calendar data
protocol ContentManageable {
    func save() throws
    func load() throws
    func export() throws -> Data
    func `import`(_ data: Data) throws
}

