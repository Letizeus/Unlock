import SwiftUI
import PhotosUI

// Main view for creating and editing holiday calendars.
// Allows users to configure calendar settings, add content, and preview the result.
struct TabViewEditor: View {
    
    @Environment(\.editorTheme) private var theme // Access the editor theme from the environment
    
    // MARK: - Properties
    
    @StateObject private var stateManager = CalendarStateManager.shared
    
    // Basic Calendar Settings
    @State private var calendarTitle = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(24 * 60 * 60 * 31) // 31 days ahead
    @State private var doorCount = Constants.Calendar.defaultDoorCount
    @State private var gridColumns = Constants.Calendar.defaultGridColumns
    @State private var unlockMode: UnlockMode = .daily
    @State private var layoutMode: GridLayoutMode = .uniform
    
    // Background Image Configuration
    @State private var selectedBackgroundImage: UIImage?
    @State private var selectedImageItem: PhotosPickerItem?
    
    // Preview and Door Management
    @State private var isPreviewActive = false
    @State private var doors: [CalendarDoor] = []
    @State private var selectedDoor: CalendarDoor?
    @State private var isEditingDoor = false
    @State private var editedDoors: [UUID: CalendarDoor] = [:] // Tracks temporary door edits
    
    // Computed property to get the number of days between start and end dates
    private var daysBetweenDates: Int {
        (Calendar.current.dateComponents([.day], from: startDate + 10, to: endDate).day ?? 0) + 2
    }
    
    let onSaveCalendar: (HolidayCalendar) -> Void // Callback function to handle saving the calendar
    
    // MARK: - View Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundLayer
                
                ScrollView {
                    VStack(spacing: theme.spacing) {
                        basicInfoSection
                        backgroundImageSection
                        previewSection
                        exportButton
                    }
                    .padding(theme.padding)
                }
            }
            .navigationTitle("Create Calendar")
            .sheet(isPresented: $isPreviewActive) {
                calendarPreview
            }
            .sheet(item: $selectedDoor) { door in
                NavigationStack {
                    DoorEditorView(
                        door: door,
                        unlockMode: unlockMode
                    ) { updatedDoor in
                        // When the door is saved:
                        // Find the index of the door in our array using its ID
                        if let index = doors.firstIndex(where: { $0.id == updatedDoor.id }) {
                            // Update the door at that index with the edited version
                            doors[index] = updatedDoor
                        }
                        // Set selectedDoor to nil to dismiss the sheet
                        selectedDoor = nil
                    }
                }
                .interactiveDismissDisabled()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    saveButton
                }
                ToolbarItem(placement: .topBarLeading) {
                    previewButton
                }
            }
            .onAppear(perform: generateDoors) // Generate initial doors when view appears
            // Update doors when dates change
            .onChange(of: startDate) { _, _ in
                generateDoors()
            }
            .onChange(of: endDate) { _, _ in
                generateDoors()
            }
            // Regenerate doors when count changes in specific mode
            .onChange(of: doorCount) { _, _ in
                if unlockMode == .specific {
                    generateDoors()
                }
            }
            // Regenerate doors when unlock mode changes
            .onChange(of: unlockMode) { _, _ in
                generateDoors()
            }
        }
    }
    
    // MARK: - UI Components
    
    // Background layer for the entire view
    private var backgroundLayer: some View {
        theme.background
            .ignoresSafeArea()
    }
    
    // Save button that becomes enabled when calendar has title and doors
    private var saveButton: some View {
        Button(action: {
            applyEdits() // Applies all edits
            saveCalendar() // Saves the calendar
        }) {
            Text("Save & Use")
                .foregroundColor(calendarTitle.isEmpty || doors.isEmpty ?
                            theme.text.opacity(0.4) :  // Disabled state
                            theme.accent)              // Enabled state
        }
        .disabled(calendarTitle.isEmpty || doors.isEmpty)
    }
    
    // Section for basic calendar information input
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing) {
            Text("Basic Information")
                .font(theme.headlineFont)
                .foregroundColor(theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            TextField("Calendar Title", text: $calendarTitle)
                .textFieldStyle(.roundedBorder)
                .font(theme.bodyFont)
            
            // Unlock mode selection
            VStack(alignment: .leading, spacing: theme.spacing) {
                Text("Unlock Mode")
                    .font(theme.bodyFont)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                
                Picker("Unlock Mode", selection: $unlockMode) {
                    Text(UnlockMode.daily.description).tag(UnlockMode.daily)
                    Text(UnlockMode.specific.description).tag(UnlockMode.specific)
                }
                .pickerStyle(.segmented)
            }
            
            // Layout Style selection
            VStack(alignment: .leading, spacing: theme.spacing) {
                Text("Layout Style (not working)")
                    .font(theme.bodyFont)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                
                Picker("Layout Mode", selection: $layoutMode) {
                    Text(GridLayoutMode.uniform.description).tag(GridLayoutMode.uniform)
                    Text(GridLayoutMode.random.description).tag(GridLayoutMode.random)
                }
                .pickerStyle(.segmented)
            }
            
            // Date selection for daily unlock mode
            if unlockMode == .daily {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    .font(theme.bodyFont)
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    .font(theme.bodyFont)
            }
            
            // Always show the stepper, but disable it in daily mode
            Stepper("Number of Doors: \(unlockMode == .daily ? daysBetweenDates : doorCount)",
                   value: $doorCount,
                   in: 1...Constants.Calendar.maxDoorCount)
                .disabled(unlockMode == .daily)
                .font(theme.bodyFont)
            
            HStack {
                Text("Grid Columns:")
                    .font(theme.bodyFont)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Stepper("\(gridColumns)", value: $gridColumns, in: 2...Constants.Calendar.maxGridColumns)
                    .font(theme.bodyFont)
            }
        }
        .padding(theme.padding)
        .background(theme.secondary)
        .cornerRadius(theme.cornerRadius)
    }
    
    // Section for background image selection
    private var backgroundImageSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing) {
            Text("Background Image")
                .font(theme.headlineFont)
                .foregroundColor(theme.text)
            
            PhotosPicker(selection: $selectedImageItem, matching: .images) {
                if let selectedBackgroundImage {
                    Image(uiImage: selectedBackgroundImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: theme.imagePickerStyle.previewHeight)
                        .cornerRadius(theme.cornerRadius)
                } else {
                    Label("Select Image", systemImage: "photo")
                        .font(theme.bodyFont)
                        .frame(maxWidth: .infinity)
                        .frame(height: theme.imagePickerStyle.previewHeight / 2)
                        .background(theme.imagePickerStyle.placeholderColor)
                        .cornerRadius(theme.cornerRadius)
                }
            }
        }
        .padding(theme.padding)
        .background(theme.secondary)
        .cornerRadius(theme.cornerRadius)
        .onChange(of: selectedImageItem) { _, _ in
            Task {
                // Try to load the selected image as transferable data
                if let data = try? await selectedImageItem?.loadTransferable(type: Data.self) {
                    selectedBackgroundImage = UIImage(data: data) // Convert the raw data into a UIImage if possible
                }
            }
        }
    }
    
    // Button to show full calendar preview
    private var previewButton: some View {
        Button(action: { isPreviewActive = true }) {
            Text("Full Preview")
                .foregroundColor(theme.accent)
        }
        .disabled(doors.isEmpty)
    }
    
    // Section showing door preview grid
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing) {
            HStack {
                Text("Preview")
                    .font(theme.headlineFont)
                    .foregroundColor(theme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                
                Spacer()
                
                clearButton
            }
            
            if doors.isEmpty {
                HStack {
                    Text("Add doors to see preview")
                        .foregroundColor(theme.text.opacity(0.6))
                        .font(theme.bodyFont)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                    Spacer()
                }
            } else {
                ScrollView {
                    let columns = Array(repeating: GridItem(.flexible(), spacing: theme.spacing), count: gridColumns)
                    LazyVGrid(columns: columns, spacing: theme.spacing) {
                        ForEach(doors) { door in
                            DoorPreviewCell(door: getCurrentDoor(door))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    // Always use the current door state when editing
                                    selectedDoor = getCurrentDoor(door)
                                }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .frame(maxHeight: theme.previewStyle.maxHeight)
            }
        }
        .padding(theme.padding)
        .background(theme.secondary)
        .cornerRadius(theme.cornerRadius)
    }
    
    // Full calendar preview view
    private var calendarPreview: some View {
        TabViewCalendar(calendar: createPreviewCalendar())
    }
    
    // Removes all edited content and regenerates doors
    private var clearButton: some View {
        Button(action: {
            editedDoors.removeAll()
            // Generate fresh doors with default content
            let calendar = Calendar.current
            
            if unlockMode == .daily {
                doorCount = daysBetweenDates
            }
            
            doors = (1...doorCount).map { number in
                let unlockDate = unlockMode == .daily
                    ? calendar.date(byAdding: .day, value: number - 1, to: startDate) ?? startDate
                    : startDate
                    
                return CalendarDoor(
                    number: number,
                    unlockDate: unlockDate,
                    isUnlocked: false,
                    content: .text("Add content for door \(number)"),
                    hasBeenOpened: false
                )
            }
        }) {
            Text("Clear")
                .foregroundColor(theme.accent)
        }
    }
    
    // Export section that allows users to export their calendar configuration
    private var exportButton: some View {
        VStack(alignment: .leading, spacing: theme.spacing) {
            Text("Export")
                .font(theme.headlineFont)
                .foregroundColor(theme.text)
            
            Button(action: {
                // Placeholder for export functionality
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export Calendar")
                        .font(theme.bodyFont)
                }
                .frame(maxWidth: .infinity)
                .padding(theme.padding)
                .background(theme.accent)
                .foregroundColor(.white)
                .cornerRadius(theme.cornerRadius)
            }
            .disabled(doors.isEmpty)
        }
        .padding(theme.padding)
        .background(theme.secondary)
        .cornerRadius(theme.cornerRadius)
    }
    
    // MARK: - Helper Functions
    
    // Saves the current calendar configuration
    private func saveCalendar() {
        // Update unlock states before saving
        let currentDate = Calendar.current.startOfDay(for: Date())
        let updatedDoors = doors.map { door in
            var updatedDoor = door
            updatedDoor.isUnlocked = currentDate >= Calendar.current.startOfDay(for: door.unlockDate)
            return updatedDoor
        }

        let calendar = HolidayCalendar(
            title: calendarTitle.isEmpty ? "Preview Calendar" : calendarTitle,
            startDate: startDate,
            endDate: endDate,
            doors: updatedDoors,
            gridColumns: gridColumns,
            backgroundImageData: selectedBackgroundImage?.jpegData(compressionQuality: 1)
        )
        onSaveCalendar(calendar)
        
        stateManager.calendar = calendar // Updates the state manager with the new calendar
    }
    
    // Generates door entries based on current settings while also preserving edits
    private func generateDoors() {
        let calendar = Calendar.current
        
        if unlockMode == .daily {
            doorCount = daysBetweenDates
        }
        
        // Creates a mapping of door numbers to their edited content, including both edited and original content
        var doorNumberToContent: [Int: DoorContent] = [:]
        // First, preserve all existing door content (both edited and non-edited)
        for door in doors {
            if let editedDoor = editedDoors[door.id] {
                doorNumberToContent[door.number] = editedDoor.content
            } else {
                doorNumberToContent[door.number] = door.content
            }
        }
        
        let newDoors = (1...doorCount).map { number in
            let unlockDate = unlockMode == .daily
                ? calendar.date(byAdding: .day, value: number - 1, to: startDate) ?? startDate
                : startDate // For specific mode, default to start date
            
            // If we have edited content for this door number, use it
            let content = doorNumberToContent[number] ?? .text("Add content for door \(number)")
            
            let newDoor = CalendarDoor(
                number: number,
                unlockDate: unlockDate,
                isUnlocked: false,
                content: content,
                hasBeenOpened: false
            )
            
            return newDoor
        }
        
        doors = newDoors
    }

    // Creates a preview calendar instance with current settings
    private func createPreviewCalendar() -> HolidayCalendar {
        // Update unlock states before creating preview
        let currentDate = Calendar.current.startOfDay(for: Date())
        let updatedDoors = doors.map { door in
            var updatedDoor = door
            updatedDoor.isUnlocked = currentDate >= Calendar.current.startOfDay(for: door.unlockDate)
            return updatedDoor
        }
        let backgroundData = selectedBackgroundImage?.jpegData(compressionQuality: 1)
        
        return HolidayCalendar(
            title: calendarTitle.isEmpty ? "Preview Calendar" : calendarTitle,
            startDate: startDate,
            endDate: endDate,
            doors: updatedDoors,
            gridColumns: gridColumns,
            backgroundImageData: backgroundData
        )
    }
    
    // Gets the current content of a door (either edited or original)
    private func getCurrentDoor(_ door: CalendarDoor) -> CalendarDoor {
        editedDoors[door.id] ?? door
    }
    
    // Applies all temporary edits when saving
    private func applyEdits() {
        doors = doors.map { door in
            editedDoors[door.id] ?? door
        }
    }
}

// MARK: - Preview Provider

#Preview {
    TabViewEditor { _ in }
}
