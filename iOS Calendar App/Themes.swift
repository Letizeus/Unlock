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
    
    // Default calendar theme configuration
    static var `default`: CalendarTheme {
        CalendarTheme(
            spacing: 12,
            cornerRadius: 12,
            padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
            titleFont: .system(.title),
            subtitleFont: .system(.title2),
            bodyFont: .system(.body),
            primary: Color(UIColor.systemBlue),
            secondary: Color(UIColor.secondarySystemBackground),
            background: Color(UIColor.systemIndigo).opacity(0.9),
            text: .white,
            accent: .green,
            doorStyle: DoorStyle(
                lockedBackground: .white.opacity(0.15),
                unlockedBackground: .green.opacity(0.2),
                todayBackground: .yellow.opacity(0.3),
                borderColor: .white.opacity(0.2),
                borderWidth: 1
            ),
            countdownStyle: CountdownStyle(
                cellWidth: 70,
                separatorColor: .white,
                backgroundColor: .white.opacity(0.1)
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
