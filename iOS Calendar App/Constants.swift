import SwiftUI

// Organized into nested enums for better categorization
enum Constants {
    // Constants related to calendar configuration and behavior
    enum Calendar {
        static let defaultYear = 2024
        static let defaultMonth = 12
        static let defaultDoorCount = 31
        static let defaultGridColumns = 4
        
        static let maxDoorCount = 1000
        static let maxGridColumns = 6
    }
    
    // Constants related to UI configuration
    enum UI {
        static let defaultSpacing: CGFloat = 12
        static let defaultCornerRadius: CGFloat = 12
        static let defaultHorizontalPadding: CGFloat = 16
        
        // Font sizes
        static let titleFontSize: CGFloat = 24 // Main titles and large numbers
        static let subtitleFontSize: CGFloat = 16 // Section headers and medium text
        static let bodyFontSize: CGFloat = 14 // Regular text and small elements
        
        // View dimensions
        static let previewMaxHeight: CGFloat = 400
        static let imagePreviewHeight: CGFloat = 200
        static let countdownCellWidth: CGFloat = 60
    }
    
    // Color constants used throughout the application
    enum Colors {
        // Background colors
        static let primaryBackground = Color(UIColor.systemIndigo).opacity(0.9) // Main app background
        static let secondaryBackground = Color(UIColor.secondarySystemBackground) // Section backgrounds in Editor
        static let tertiaryBackground = Color(UIColor.tertiarySystemBackground) // Door backgrounds in Editor
        
        // Door states
        static let doorUnlocked = Color.green.opacity(0.2)
        static let doorLocked = Color.white.opacity(0.15)
        static let doorToday = Color.yellow.opacity(0.3)
        
        // Text colors
        static let primaryText = Color.primary
        static let secondaryText = Color.secondary
        static let whiteText = Color.white
        
        // Overlay colors
        static let darkOverlay = Color.black.opacity(0.6) // Used over background images
        static let lightOverlay = Color.white.opacity(0.1) // Used for highlight effects
        
        // Border colors
        static let borderColor = Color.white.opacity(0.2) // Border color for elements needing subtle separation
    }
    
    // Constants related to animations
    enum Animation {
    }
}
