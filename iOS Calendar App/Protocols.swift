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
