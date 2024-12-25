import SwiftUI

// Organized into nested enums for better categorization
enum Constants {
    // Constants related to calendar configuration and behavior
    enum Calendar {
        static let defaultYear = Foundation.Calendar.current.component(.year, from: Date())
        static let defaultMonth = Foundation.Calendar.current.component(.month, from: Date())
        static let defaultDoorCount: Int = {
            let range = Foundation.Calendar.current.range(of: .day, in: .month, for: Date())
            return range?.count ?? 31
        }()
        static let maxDoorCount = 1000
        
        static let defaultGridColumns = 4
        static let maxGridColumns = 6
    }
    
    // Constants related to animations
    enum Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.3)
    }
}
