import SwiftUI

// Provides a view to manage and access both exported and imported calendars
// Allows users to view, manage and switch between their exported and imported holiday calendars
struct TabViewLibrary: View {
    @Environment(\.editorTheme) private var theme
    @StateObject private var stateManager = CalendarStateManager.shared
    
    // MARK: - Properties
    
    @State private var selectedSegment = 0 // Controls which view is currently displayed (0 = exported, 1 = imported)
    @State private var showingImporter = false // Controls the presentation of the file importer
    
    // MARK: - View Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segment control for switching between created and received
                Picker("Calendar Type", selection: $selectedSegment) {
                    Text("Exported").tag(0)
                    Text("Imported").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if selectedSegment == 0 {
                    exportedCalendarsView
                } else {
                    importedCalendarsView
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingImporter = true }) {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.holidayCalendar],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
        }
    }
    
    // MARK: - UI Components
    
    // Displays all exported calendars in a scrollable list
    private var exportedCalendarsView: some View {
        ScrollView {
            LazyVStack(spacing: theme.spacing) {
                ForEach(0..<5) { index in
                    calendarCard(
                        title: "Exported Calendar \(index + 1)",
                        date: Date(),
                        type: .exported
                    )
                }
            }
            .padding()
        }
    }
    
    // Displays all imported calendars in a scrollable list
    private var importedCalendarsView: some View {
        ScrollView {
            LazyVStack(spacing: theme.spacing) {
                ForEach(0..<3) { index in
                    calendarCard(
                        title: "Imported Calendar \(index + 1)",
                        date: Date(),
                        type: .imported
                    )
                }
            }
            .padding()
        }
    }
    
    // Creates a card view for displaying calendar information and actions
    private func calendarCard(title: String, date: Date, type: CalendarType) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title and type icon
            HStack {
                Text(title)
                    .font(theme.subtitleFont)
                    .foregroundColor(theme.text)
                Spacer()
                Image(systemName: type == .exported ? "pencil.circle" : "gift.circle")
                    .foregroundColor(theme.accent)
            }
            
            // Calendar date
            Text(formatDate(date))
                .font(theme.footnoteFont)
                .foregroundColor(theme.text.opacity(0.6))
            
            // Action buttons
            HStack {
                Button(action: {
                    // Open calendar action
                }) {
                    Text("Open")
                        .font(theme.bodyFont)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(theme.accent)
                        .cornerRadius(8)
                }
                
                // Share button only appears for exported calendars
                if type == .exported {
                    Button(action: {
                        // Share calendar action
                    }) {
                        Text("Share")
                            .font(theme.bodyFont)
                            .foregroundColor(theme.accent)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(theme.accent.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    // Delete calendar action
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(theme.secondary)
        .cornerRadius(theme.cornerRadius)
    }
    
    // MARK: - Helper Functions
    
    // Formats a date into a readable string for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // Handles the import process when a new calendar file is selected
    private func handleImport(_ result: Result<[URL], Error>) {
        // Handle calendar import
    }
}

// MARK: - Preview

#Preview {
    TabViewLibrary()
        .environment(\.editorTheme, EditorTheme.default)
}
