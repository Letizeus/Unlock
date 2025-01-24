import SwiftUI

// Provides a view to manage and access both exported and imported calendars
// Allows users to view, manage and switch between their exported and imported holiday calendars
struct TabViewLibrary: View {
    @Environment(\.editorTheme) private var theme
    @StateObject private var stateManager = CalendarStateManager.shared
    
    // MARK: - Properties
    
    @State private var selectedSegment = 0 // Controls which view is currently displayed (0 = exported, 1 = imported)
    @State private var showingImporter = false // Controls the presentation of the file importer
    @State private var showingError = false // Controls the presentation of error alerts
    @State private var errorMessage = "" // Stores the current error message
    @State private var libraryItems: [LibraryItem] = [] // Holds the array of library items (calendars)
    
    let onLoadCalendar: () -> Void // Callback function for when a calendar is loaded
    
    // MARK: - View Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Picker to switch between exported and imported calendars
                Picker("Calendar Type", selection: $selectedSegment) {
                    Text("Exported").tag(0)
                    Text("Imported").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Shows an empty state view if there are no library items
                if libraryItems.isEmpty {
                    emptyStateView
                } else {
                    calendarList
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
            // Presents the file importer when showingImporter is true
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.holidayCalendar],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            // Displays an error alert when showingError is true
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear(perform: loadLibraryItems) // Loads library items when the view appears
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToImportedSection"))) { _ in
                selectedSegment = 1 // Switches to imported section
            }
        }
    }
    
    // MARK: - UI Components
    
    // Empty state view shown when there are no library items
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 50))
                .foregroundColor(theme.text.opacity(0.3))
            
            Text(selectedSegment == 0 ? "No exported calendars yet" : "No imported calendars yet")
                .font(theme.bodyFont)
                .foregroundColor(theme.text.opacity(0.6))
            
            // Shows an import button if the imported segment is selected
            if selectedSegment == 1 {
                Button(action: { showingImporter = true }) {
                    Text("Import Calendar")
                        .font(theme.bodyFont)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(theme.accent)
                        .cornerRadius(10)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    // List view that displays the calendars based on the selected segment
    private var calendarList: some View {
        let filteredItems = libraryItems.filter { item in
            selectedSegment == 0 ? item.type == .exported : item.type == .imported
        }
        
        return Group {
            if filteredItems.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(filteredItems) { item in
                        calendarCard(item)
                            .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    // Creates a card view for displaying calendar information and actions
    private func calendarCard(_ item: LibraryItem) -> some View {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        return VStack(alignment: .leading, spacing: 8) {
            Text(item.calendar.title)
                .font(theme.subtitleFont)
                .foregroundColor(theme.text)
            
            Text("Added \(formatter.string(from: item.dateAdded))")
                .font(theme.footnoteFont)
                .foregroundColor(theme.text.opacity(0.6))
            
            Text("\(item.calendar.doors.count) doors")
                .font(theme.footnoteFont)
                .foregroundColor(theme.text.opacity(0.6))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.secondary)
        .cornerRadius(theme.cornerRadius)
        // Swipe action to delete the calendar item
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                deleteItem(item)
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete")
                }
                .font(theme.bodyFont)
                .padding(.vertical, 8)
            }
            .tint(Color.red.opacity(0.9))
        }
        .onTapGesture {
            loadCalendar(item.calendar)
        }
    }
    
    // MARK: - Helper Functions
    
    // Loads library items from storage
    private func loadLibraryItems() {
        do {
            libraryItems = try AppData.shared.loadLibraryItems()
        } catch {
            showError("Failed to load library items: \(error.localizedDescription)")
        }
    }
    
    // Handles the import process when a new calendar file is selected
    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                showError("No file selected")
                return
            }
            
            guard url.startAccessingSecurityScopedResource() else {
                showError("Unable to access the selected file")
                return
            }
            
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let data = try Data(contentsOf: url)
                let calendar = try AppData.shared.importCalendar(from: data)
                
                try AppData.shared.addToLibrary(calendar, type: .imported)
                loadLibraryItems()
                loadCalendar(calendar)
            } catch {
                showError("Failed to import calendar: \(error.localizedDescription)")
            }
            
        case .failure(let error):
            showError("Error selecting file: \(error.localizedDescription)")
        }
    }
    
    // Deletes a library item from storage
    private func deleteItem(_ item: LibraryItem) {
        do {
            try AppData.shared.deleteLibraryItem(withId: item.id)
            loadLibraryItems()
        } catch {
            showError("Failed to delete item: \(error.localizedDescription)")
        }
    }
    
    // Creates a fresh calendar with reset states
    private func loadCalendar(_ calendar: HolidayCalendar) {
        let resetCalendar = HolidayCalendar(
            title: calendar.title,
            startDate: calendar.startDate,
            endDate: calendar.endDate,
            doors: calendar.doors.map { door in
                CalendarDoor(
                    number: door.number,
                    unlockDate: door.unlockDate,
                    isUnlocked: Calendar.current.startOfDay(for: Date()) >= Calendar.current.startOfDay(for: door.unlockDate),
                    content: door.content,
                    hasBeenOpened: door.hasBeenOpened
                )
            },
            gridColumns: calendar.gridColumns,
            backgroundImageData: calendar.backgroundImageData,
            backgroundColor: calendar.backgroundColor,
            doorColor: calendar.doorColor
        )
        
        DispatchQueue.main.async {
            stateManager.reset(with: resetCalendar) // Resets the entire state manager
            onLoadCalendar()
        }
    }
    
    // Shows an error alert with the specified message
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - Preview

#Preview {
    TabViewLibrary(onLoadCalendar: {})
        .environment(\.editorTheme, EditorTheme.default)
}
