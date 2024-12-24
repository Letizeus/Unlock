import SwiftUI
import Foundation

// Protocol defining the core functionality for managing calendar content
// Implementers of this protocol can save, load, export, and import calendar data
protocol ContentManageable {
    func save() throws
    func load() throws
    func export() throws -> Data
    func `import`(_ data: Data) throws
}

// Protocol for defining theme properties

// MARK: - Theme Protocols

protocol ViewTheme {
    var spacing: CGFloat { get }
    var cornerRadius: CGFloat { get }
    var padding: EdgeInsets { get }
}

// Note: Editor crashes with more fonts... (must be fixed)
protocol Typography {
    var titleFont: Font { get }
    var subtitleFont: Font { get }
    var bodyFont: Font { get }
}

protocol ColorPalette {
    var primary: Color { get }
    var secondary: Color { get }
    var background: Color { get }
    var text: Color { get }
    var accent: Color { get }
}
