import SwiftUI
import Foundation

protocol ContentManageable {
    func save() throws
    func load() throws
    func export() throws -> Data
    func `import`(_ data: Data) throws
}
