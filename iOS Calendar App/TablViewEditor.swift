import SwiftUI
import PhotosUI

// Main view for creating and editing holiday calendars
// Allows users to configure calendar settings, add content, and preview the result
struct TabViewEditor: View {
    
    // MARK: - Properties
    
    @Environment(\.editorTheme) private var theme
    
    @StateObject private var stateManager = EditorStateManager.shared // Main state manager for the editor
    
    @State private var selectedImageItem: PhotosPickerItem? // Tracks the selected image for background customization
    
    @State private var isPreviewActive = false // Controls the visibility of the calendar preview
    
    @State private var selectedDoor: CalendarDoor? // Currently selected door for editing
    
    @State private var showingImporter = false
    
    let onSaveCalendar: (HolidayCalendar) -> Void // Callback for when calendar is saved
    
    // Computed property to get days between start and end dates
    private var daysBetweenDates: Int {
        (Calendar.current.dateComponents([.day],
            from: stateManager.model.startDate,
            to: stateManager.model.endDate).day ?? 0) + 1
    }
    
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
                        filesButton
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
                        unlockMode: stateManager.model.unlockMode
                    ) { updatedDoor in
                        // When the door is saved:
                        // Finds the index of the door in our array using its ID
                        if let index = stateManager.model.doors.firstIndex(where: { $0.id == updatedDoor.id }) {
                            // Updates the door at that index with the edited version
                            stateManager.model.doors[index] = updatedDoor
                        }
                        // Sets selectedDoor to nil to dismiss the sheet
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
            .onAppear(perform: generateDoors) // Generates initial doors when view appears
            // Updates doors when dates change
            .onChange(of: stateManager.model.startDate) { generateDoors() }
            .onChange(of: stateManager.model.endDate) { generateDoors() }
            // Regeneratse doors when count changes in specific mode
            .onChange(of: stateManager.model.doorCount) {
                if stateManager.model.unlockMode == .specific {
                    generateDoors()
                }
            }
            .onChange(of: stateManager.model.unlockMode) { generateDoors() } // Regenerates doors when unlock mode changes
        }
    }
    
    // MARK: - UI Components
    
    // Background layer for the entire view
    private var backgroundLayer: some View {
        theme.background
            .ignoresSafeArea()
    }
    
    // Saves button that becomes enabled when calendar has title and doors
    private var saveButton: some View {
        Button(action: saveCalendar) {
            Text("Save & Use")
                .foregroundColor(stateManager.model.calendarTitle.isEmpty ||
                               stateManager.model.doors.isEmpty ?
                               theme.text.opacity(0.4) : // Disabled state
                               theme.accent)             // Enabled state
        }
        .disabled(stateManager.model.calendarTitle.isEmpty || stateManager.model.doors.isEmpty)
    }
    
    // Section for basic calendar information input
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing) {
            Text("Basic Information")
                .font(theme.headlineFont)
                .foregroundColor(theme.text)
            
            TextField("Calendar Title", text: $stateManager.model.calendarTitle)
                .textFieldStyle(.roundedBorder)
                .font(theme.bodyFont)
            
            // Unlock mode selection
            VStack(alignment: .leading, spacing: theme.spacing) {
                Text("Unlock Mode")
                    .font(theme.bodyFont)
                
                Picker("Unlock Mode", selection: $stateManager.model.unlockMode) {
                    Text(UnlockMode.daily.description).tag(UnlockMode.daily)
                    Text(UnlockMode.specific.description).tag(UnlockMode.specific)
                }
                .pickerStyle(.segmented)
            }
            
            // Layout mode selection
            VStack(alignment: .leading, spacing: theme.spacing) {
                Text("Layout Style")
                    .font(theme.bodyFont)
                
                Picker("Layout Mode", selection: $stateManager.model.layoutMode) {
                    Text(GridLayoutMode.uniform.description).tag(GridLayoutMode.uniform)
                    Text(GridLayoutMode.random.description).tag(GridLayoutMode.random)
                }
                .pickerStyle(.segmented)
            }
            
            // Date selection for daily unlock mode
            if stateManager.model.unlockMode == .daily {
                DatePicker("Start Date",
                          selection: $stateManager.model.startDate,
                          displayedComponents: .date)
                    .font(theme.bodyFont)
                DatePicker("End Date",
                          selection: $stateManager.model.endDate,
                          displayedComponents: .date)
                    .font(theme.bodyFont)
            }
            
            // Door count stepper
            Stepper(
                "Number of Doors: \(stateManager.model.unlockMode == .daily ? daysBetweenDates : stateManager.model.doorCount)",
                value: $stateManager.model.doorCount,
                in: 1...Constants.Calendar.maxDoorCount
            )
            .disabled(stateManager.model.unlockMode == .daily)
            .font(theme.bodyFont)
            
            // Grid columns stepper
            HStack {
                Text("Grid Columns:")
                    .font(theme.bodyFont)
                Stepper("\(stateManager.model.gridColumns)",
                        value: $stateManager.model.gridColumns,
                        in: 2...Constants.Calendar.maxGridColumns)
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
                if let imageData = stateManager.model.backgroundImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
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
        .onChange(of: selectedImageItem) { _, newValue in
            Task {
                // Tries to load the selected image as transferable data
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    stateManager.model.backgroundImageData = data // Converts the raw data into a UIImage if possible
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
        .disabled(stateManager.model.doors.isEmpty)
    }
    
    // Section showing door preview grid
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing) {
            HStack {
                Text("Preview")
                    .font(theme.headlineFont)
                    .foregroundColor(theme.text)
                
                Spacer()
                
                clearButton
            }
            
            if stateManager.model.doors.isEmpty {
                Text("Add doors to see preview")
                    .foregroundColor(theme.text.opacity(0.6))
                    .font(theme.bodyFont)
            } else {
                doorsGrid
            }
        }
        .padding(theme.padding)
        .background(theme.secondary)
        .cornerRadius(theme.cornerRadius)
    }
    
    private var doorsGrid: some View {
        ScrollView {
            let columns = Array(repeating: GridItem(.flexible(), spacing: theme.spacing),
                              count: stateManager.model.gridColumns)
            LazyVGrid(columns: columns, spacing: theme.spacing) {
                ForEach(stateManager.model.doors) { door in
                    DoorPreviewCell(door: door)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Always use the current door state when editing
                            selectedDoor = door
                        }
                }
            }
        }
        .scrollIndicators(.hidden)
        .frame(maxHeight: theme.previewStyle.maxHeight)
    }
    
    // Full calendar preview view
    private var calendarPreview: some View {
        TabViewCalendar(calendar: stateManager.model.createCalendar())
    }
    
    // Removes all edited content and regenerates doors
    private var clearButton: some View {
        Button(action: {
            let currentDoorCount = stateManager.model.unlockMode == .daily ? daysBetweenDates : stateManager.model.doorCount
            
            // Creates fresh doors with default content
            let newDoors = (1...currentDoorCount).map { number in
                let unlockDate = stateManager.model.unlockMode == .daily
                    ? Calendar.current.date(byAdding: .day, value: number - 1, to: stateManager.model.startDate) ?? stateManager.model.startDate
                    : stateManager.model.startDate
                    
                return CalendarDoor(
                    number: number,
                    unlockDate: unlockDate,
                    isUnlocked: false,
                    content: .text("Add content for door \(number)"),
                    hasBeenOpened: false
                )
            }
            
            stateManager.model.doors = newDoors
        }) {
            Text("Clear")
                .foregroundColor(theme.accent)
        }
    }
    
    // Files section that allows users to export or reset their calendar configuration or import an external calendar
    private var filesButton: some View {
        VStack(alignment: .leading, spacing: theme.spacing) {
            Text("Files")
                .font(theme.headlineFont)
                .foregroundColor(theme.text)
            
            Button(action: {
                do {
                    try stateManager.exportCalendar()
                } catch {
                    print("Error exporting calendar: \(error)")
                }
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
            .disabled(stateManager.model.doors.isEmpty)
            
            importButton
            
            // Reset Button
            Button(action: {
                stateManager.reset() // Resets the editor state to defaults
                generateDoors()
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset Calendar")
                        .font(theme.bodyFont)
                }
                .frame(maxWidth: .infinity)
                .padding(theme.padding)
                .background(theme.accent.opacity(0.4))
                .foregroundColor(theme.accent)
                .cornerRadius(theme.cornerRadius)
            }
        }
        .padding(theme.padding)
        .background(theme.secondary)
        .cornerRadius(theme.cornerRadius)
    }
    
    private var importButton: some View {
        Button(action: { showingImporter = true }) {
            HStack {
                Image(systemName: "square.and.arrow.down")
                Text("Import Calendar")
                    .font(theme.bodyFont)
            }
            .frame(maxWidth: .infinity)
            .padding(theme.padding)
            .background(theme.accent)
            .foregroundColor(.white)
            .cornerRadius(theme.cornerRadius)
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.holidayCalendar],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                
                guard url.startAccessingSecurityScopedResource() else {
                    print("Failed to access the file")
                    return
                }
                
                defer {
                    url.stopAccessingSecurityScopedResource()
                }
                
                do {
                    let data = try Data(contentsOf: url)
                    
                    try? FileManager.default.removeItem(at: AppStorage.shared.calendarURL) // clears the existing state in AppStorage
                    
                    let calendar = try AppStorage.shared.importCalendar(from: data)
                    
                    // Creates a fresh calendar with reset states
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
                        backgroundImageData: calendar.backgroundImageData
                    )
                    
                    DispatchQueue.main.async {
                        CalendarStateManager.shared.reset(with: resetCalendar) // Resets the entire state manager
                        self.onSaveCalendar(resetCalendar)
                    }
                } catch {
                    print("Error importing calendar: \(error.localizedDescription)")
                }
            case .failure(let error):
                print("Error selecting file: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Helper Functions
    
    // Saves the current calendar configuration and notifies the parent view
    // Only enabled when the calendar has a title and at least one door
    private func saveCalendar() {
        let calendar = stateManager.model.createCalendar()
        onSaveCalendar(calendar)
    }
    
    // Generates door entries based on current settings while also preserving edits
    private func generateDoors() {
        let calendar = Calendar.current
        let currentDate = calendar.startOfDay(for: Date())
        
        if stateManager.model.unlockMode == .daily {
            stateManager.model.doorCount = daysBetweenDates
        }
        
        // Creates new doors while preserving existing content where possible
        var doorNumberToContent: [Int: DoorContent] = [:]
        for door in stateManager.model.doors {
            doorNumberToContent[door.number] = door.content
        }
        
        let newDoors = (1...stateManager.model.doorCount).map { number in
            let unlockDate = stateManager.model.unlockMode == .daily
                ? calendar.date(byAdding: .day, value: number - 1, to: stateManager.model.startDate)
                    ?? stateManager.model.startDate
                    : stateManager.model.startDate // For specific mode, default to start date
            
            // If we have edited content for this door number, use it
            let content = doorNumberToContent[number] ?? .text("Add content for door \(number)")
            
            let isUnlocked = calendar.startOfDay(for: unlockDate) <= currentDate
            
            return CalendarDoor(
                number: number,
                unlockDate: unlockDate,
                isUnlocked: isUnlocked,
                content: content,
                hasBeenOpened: false
            )
        }
        
        stateManager.model.doors = newDoors
    }
}

// MARK: - Preview Provider

#Preview {
    TabViewEditor { _ in }
}
