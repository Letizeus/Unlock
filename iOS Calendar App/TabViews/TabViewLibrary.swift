import SwiftUI

// Provides a view to manage and access both exported and imported calendars
// Allows users to view, manage and switch between their exported and imported holiday calendars
struct TabViewLibrary: View {
    @Environment(\.editorTheme) private var theme
    @StateObject private var stateManager = CalendarStateManager.shared
    
    // MARK: - Properties
    
    @AppStorage("librarySelectedSegment") private var selectedSegment = 0 // Controls which view is currently displayed (0 = exported, 1 = imported)
    @State private var showingImporter = false // Controls the presentation of the file importer
    @State private var showingError = false // Controls the presentation of error alerts
    @State private var errorMessage = "" // Stores the current error message
    @State private var libraryItems: [LibraryItem] = [] // Holds the array of library items (calendars)
    
    @State private var selectedCalendarForExport: LibraryItem? // Tracks calendar selected for export

    
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
                
                // Filters items based on selected segment
                let filteredItems = libraryItems.filter { item in
                    selectedSegment == 0 ? item.type == .exported : item.type == .imported
                }
                // Shows an empty state view if there are no library items
                if filteredItems.isEmpty {
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
        .sorted { $0.isPinned && !$1.isPinned } // Sorts pinned items to the top
        
        return List(filteredItems) { item in
            calendarCard(item)
                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }
    
    // Creates a card view for displaying calendar information and actions
    private func calendarCard(_ item: LibraryItem) -> some View {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        return VStack(alignment: .leading, spacing: 8) {
            // Background Preview
            ZStack {
                if let backgroundData = item.calendar.backgroundImageData,
                   let uiImage = UIImage(data: backgroundData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))
                        .overlay {
                            Color(UIColor.systemBackground)
                                .opacity(0.2)
                        }
                } else if item.calendar.backgroundColor != .clear {
                    item.calendar.backgroundColor
                        .frame(height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))
                        .overlay {
                            Color(UIColor.systemBackground)
                                .opacity(0.2)
                        }
                } else {
                    theme.secondary
                        .frame(height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))
                }
                
                // Door Color Preview
                if item.calendar.doorColor != .clear {
                    HStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 6)
                            .fill(item.calendar.doorColor)
                            .frame(width: 30, height: 30)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(radius: 2)
                            .padding(8)
                    }
                }
            }
            HStack(spacing: 0) {
                if item.isPinned {
                    Image(systemName: "pin.fill")
                        .foregroundColor(.orange)
                        .font(theme.subtitleFont)
                        .padding(.leading)
                        .padding(.bottom)
                }

                VStack(alignment: .leading, spacing: 4) {
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
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
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
            .tint(Color.red)
        }
        // Swipe action to edit & pin the calendar item
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            if item.type == .exported {
                Button {
                    loadIntoEditor(item.calendar)
                } label: {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(theme.bodyFont)
                    .padding(.vertical, 8)
                }
                .tint(theme.accent)
            } else {
                Button {
                    togglePin(item)
                } label: {
                    HStack {
                        Image(systemName: item.isPinned ? "pin.slash.fill" : "pin.fill")
                        Text(item.isPinned ? "Unpin" : "Pin")
                    }
                    .font(theme.bodyFont)
                    .padding(.vertical, 8)
                }
                .tint(item.isPinned ? .gray : .orange)
            }
        }
        .onTapGesture {
            loadCalendar(item.calendar)
        }
        .contextMenu {
            Button {
                shareCalendar(item.calendar)
            } label: {
                Label("Shared Calendar", systemImage: "square.and.arrow.up")
            }
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
                NotificationCenter.default.post(name: NSNotification.Name("SwitchToImportedSection"), object: nil)
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
    
    // Loads an exported calendar into the editor for modification
    private func loadIntoEditor(_ calendar: HolidayCalendar) {
        // Updates the editor state with the calendar data
        var editorModel = EditorModel()
        editorModel.calendarTitle = calendar.title
        editorModel.startDate = calendar.startDate
        editorModel.endDate = calendar.endDate
        editorModel.doorCount = calendar.doors.count
        editorModel.gridColumns = calendar.gridColumns
        editorModel.backgroundImageData = calendar.backgroundImageData
        editorModel.backgroundColor = calendar.backgroundColor
        editorModel.doorColor = calendar.doorColor
        editorModel.doors = calendar.doors
        
        // Resets the editor state with the new model
        EditorStateManager.shared.reset()
        EditorStateManager.shared.model = editorModel
        
        NotificationCenter.default.post(name: NSNotification.Name("SwitchToEditorTab"), object: nil)
    }
    
    // Shares a calendar
    private func shareCalendar(_ calendar: HolidayCalendar) {
        do {
            let (exportData, filename) = try AppData.shared.exportCalendar(calendar)
            
            // Creates a temporary file URL
            let tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try exportData.write(to: tempFileURL)
            
            // Retrieves the current window scene and root view controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                // Creates activity view controller for sharing the exported file
                let activityViewController = UIActivityViewController(
                    activityItems: [tempFileURL],
                    applicationActivities: nil
                )
                
                // Cleans up the temporary file after sharing
                activityViewController.completionWithItemsHandler = { _, _, _, _ in
                    try? FileManager.default.removeItem(at: tempFileURL)
                }
                
                rootViewController.present(activityViewController, animated: true)
            }
        } catch {
            showError("Failed to export calendar: \(error.localizedDescription)")
        }
    }
    
    // Toggles the pinned state of a library item
    private func togglePin(_ item: LibraryItem) {
        // Finds the item in the array
        if let index = libraryItems.firstIndex(where: { $0.id == item.id }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                libraryItems[index].isPinned.toggle() // Toggles the isPinned state
            }
            try? AppData.shared.saveLibraryItems(libraryItems)
        }
    }
}

// MARK: - Preview

#Preview {
    TabViewLibrary(onLoadCalendar: {})
        .environment(\.editorTheme, EditorTheme.default)
}
