import SwiftUI

enum Constants {
    enum Calendar {
        static let doorCount = 24
        
        static let defaultYear = 2024
        static let defaultMonth = 12
    }
    
    enum UI {
    }
    
    enum Colors {
        static let primaryBackground = Color(UIColor.systemIndigo).opacity(0.9)
        
        static let doorUnlocked = Color.green.opacity(0.2)
        static let doorLocked = Color.white.opacity(0.15)
        static let doorToday = Color.yellow.opacity(0.3)
    }
    
    enum Animation {
    }
}
