import SwiftUI

// MARK: - Calendar Specific Theme

struct CalendarTheme: ViewTheme, Typography, ColorPalette {
    // ViewTheme
    let spacing: CGFloat
    let cornerRadius: CGFloat
    let padding: EdgeInsets
    
    // Typography
    let titleFont: Font
    let subtitleFont: Font
    let bodyFont: Font
    let headlineFont: Font
    let footnoteFont: Font
    let captionFont: Font
    
    // ColorPalette
    let primary: Color
    let secondary: Color
    let background: Color
    let text: Color
    let accent: Color
    
    // Calendar specific properties
    struct DoorStyle {
        let lockedBackground: Color
        let unlockedBackground: Color
        let todayBackground: Color
        let completedBackground: Color
        let borderColor: Color
        let borderWidth: CGFloat
    }
    
    struct CountdownStyle {
        let cellWidth: CGFloat
        let separatorColor: Color
        let backgroundColor: Color
    }
    
    let doorStyle: DoorStyle
    let countdownStyle: CountdownStyle
    
    // Default theme that adapts to system appearance
    static var `default`: CalendarTheme {
        return lightMode
    }
    
    // Default Light Mode calendar theme configuration
    static var lightMode: CalendarTheme {
        CalendarTheme(
            // Base Theme Properties
            spacing: 16,
            cornerRadius: 16,
            padding: EdgeInsets(top: 24, leading: 20, bottom: 24, trailing: 20),
            
            // Typography
            titleFont: .system(.title, design: .rounded),
            subtitleFont: .system(.title2, design: .rounded),
            bodyFont: .system(.body, design: .rounded),
            headlineFont: .headline,
            footnoteFont: .footnote,
            captionFont: .caption,
            
            // Color Palette
            primary: Color(red: 94/255, green: 92/255, blue: 230/255),  // Same purple for consistency
            secondary: Color.black.opacity(0.05),
            background: Color(red: 242/255, green: 242/255, blue: 247/255),  // Light iOS background
            text: Color(red: 28/255, green: 28/255, blue: 30/255),  // Dark text for contrast
            accent: Color(red: 94/255, green: 92/255, blue: 230/255),  // Same accent
            
            // Door Styling
            doorStyle: DoorStyle(
                lockedBackground: Color.white.opacity(0.7),
                unlockedBackground: Color(red: 94/255, green: 92/255, blue: 230/255).opacity(0.2),
                todayBackground: Color(red: 94/255, green: 92/255, blue: 230/255).opacity(0.4),
                completedBackground: Color(red: 94/255, green: 92/255, blue: 230/255),
                borderColor: Color.black.opacity(0.2),
                borderWidth: 1.5
            ),
            
            // Countdown Styling
            countdownStyle: CountdownStyle(
                cellWidth: 75,
                separatorColor: Color(red: 28/255, green: 28/255, blue: 30/255).opacity(0.8),
                backgroundColor: Color.white.opacity(0.7)
            )
        )
    }
    
    // Default Dark Mode calendar theme configuration
    static var darkMode: CalendarTheme {
        CalendarTheme(
            // Base Theme Properties
            spacing: 16,
            cornerRadius: 16,
            padding: EdgeInsets(top: 24, leading: 20, bottom: 24, trailing: 20),
            
            // Typography
            titleFont: .system(.title, design: .rounded),
            subtitleFont: .system(.title2, design: .rounded),
            bodyFont: .system(.body, design: .rounded),
            headlineFont: .headline,
            footnoteFont: .footnote,
            captionFont: .caption,
            
            // Color Palette
            primary: Color(red: 94/255, green: 92/255, blue: 230/255),  // Modern purple
            secondary: Color(UIColor.secondarySystemBackground),
            background: Color(UIColor.systemBackground),
            text: .white,
            accent: Color(red: 94/255, green: 92/255, blue: 230/255),  // Matching accent (Same as primary color)
            
            // Door Styling
            doorStyle: DoorStyle(
                lockedBackground: Color(red: 44/255, green: 44/255, blue: 46/255).opacity(0.7),  // Dark gray, slightly lighter than background
                unlockedBackground: Color(red: 94/255, green: 92/255, blue: 230/255).opacity(0.2),
                todayBackground: Color(red: 94/255, green: 92/255, blue: 230/255).opacity(0.4),
                completedBackground: Color(red: 94/255, green: 92/255, blue: 230/255),
                borderColor: Color.white.opacity(0.1),
                borderWidth: 1.5
            ),
            
            // Countdown Styling
            countdownStyle: CountdownStyle(
                cellWidth: 75,
                separatorColor: Color.white.opacity(0.8),
                backgroundColor: Color(red: 44/255, green: 44/255, blue: 46/255).opacity(0.7) // Dark gray
            )
        )
    }
}

// MARK: - Editor Specific Theme

struct EditorTheme: ViewTheme, Typography, ColorPalette {
    // ViewTheme
    let spacing: CGFloat
    let cornerRadius: CGFloat
    let padding: EdgeInsets
    
    // Typography
    let titleFont: Font
    let subtitleFont: Font
    let bodyFont: Font
    let headlineFont: Font
    let footnoteFont: Font
    let captionFont: Font
    
    // ColorPalette
    let primary: Color
    let secondary: Color
    let background: Color
    let text: Color
    let accent: Color
    
    // Editor specific properties
    struct PreviewStyle {
        let maxHeight: CGFloat // Maximum height for preview container
        let backgroundColor: Color // Background color for preview area
    }
    
    struct ImagePickerStyle {
        let previewHeight: CGFloat // Height for image previews
        let placeholderColor: Color // Color for placeholder when no image selected
    }
    
    let previewStyle: PreviewStyle
    let imagePickerStyle: ImagePickerStyle
    
    // Default editor theme configuration
    static var `default`: EditorTheme {
        EditorTheme(
            spacing: 16,
            cornerRadius: 12,
            padding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20),
            
            titleFont: .system(.title, design: .default),
            subtitleFont: .system(.title2),
            bodyFont: .system(.body),
            headlineFont: .headline,
            footnoteFont: .footnote,
            captionFont: .caption,
            
            primary: Color(UIColor.systemBlue),
            secondary: Color(UIColor.secondarySystemBackground),
            background: Color(UIColor.systemBackground),
            text: .primary,
            accent: .blue,
            
            previewStyle: PreviewStyle(
                maxHeight: 400,
                backgroundColor: Color(UIColor.tertiarySystemBackground)
            ),
            
            imagePickerStyle: ImagePickerStyle(
                previewHeight: 200,
                placeholderColor: Color(UIColor.tertiarySystemBackground)
            )
        )
    }
}

// MARK: - Map Specific Theme

struct MapTheme: ViewTheme, Typography, ColorPalette {
    // ViewTheme
    let spacing: CGFloat
    let cornerRadius: CGFloat
    let padding: EdgeInsets
    
    // Typography
    let titleFont: Font
    let subtitleFont: Font
    let bodyFont: Font
    let headlineFont: Font
    let footnoteFont: Font
    let captionFont: Font
    
    // ColorPalette
    let primary: Color
    let secondary: Color
    let background: Color
    let text: Color
    let accent: Color
    
    // Map specific properties
    struct RoadStyle {
        let color: Color
        let width: CGFloat
        let nodeSpacing: CGFloat
    }
    
    struct CheckpointStyle {
        let size: CGFloat
        let unlockedColor: Color
        let lockedColor: Color
        let completedColor: Color
        let iconSize: CGFloat
        let shadowRadius: CGFloat
    }
    
    struct DateLabelStyle {
        let width: CGFloat
        let alignment: TextAlignment
    }
    
    let roadStyle: RoadStyle
    let checkpointStyle: CheckpointStyle
    let dateLabelStyle: DateLabelStyle
    
    // Default map theme configuration
    static var `default`: MapTheme {
        MapTheme(
            spacing: 16,
            cornerRadius: 12,
            padding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20),
            
            titleFont: .system(.title, design: .rounded),
            subtitleFont: .system(.title2, design: .rounded),
            bodyFont: .system(.body, design: .rounded),
            headlineFont: .headline,
            footnoteFont: .footnote,
            captionFont: .caption,
            
            primary: Color(red: 94/255, green: 92/255, blue: 230/255),
            secondary: Color(UIColor.secondarySystemBackground),
            background: Color(UIColor.systemBackground),
            text: .primary,
            accent: .blue,
            
            roadStyle: RoadStyle(
                color: Color.gray.opacity(0.3),
                width: 4,
                nodeSpacing: 60
            ),
            
            checkpointStyle: CheckpointStyle(
                size: 80,
                unlockedColor: Color(red: 94/255, green: 92/255, blue: 230/255),
                lockedColor: Color.white.opacity(0.7),
                completedColor: .yellow,
                iconSize: 30,
                shadowRadius: 4
            ),
            
            dateLabelStyle: DateLabelStyle(
                width: 100,
                alignment: .leading
            )
        )
    }
}
