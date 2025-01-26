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
            
            // Destinction if iPad to provide view with fullScreenCover instead of sheet
            if UIDevice.current.userInterfaceIdiom == .pad {
                ZStack {
                    backgroundLayer
                    
                    ScrollView {
                        VStack(spacing: theme.spacing) {
                            basicInfoSection
                            backgroundStyleSection
                            doorStyleSection
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
            } else {
                ZStack {
                    backgroundLayer
                    
                    ScrollView {
                        VStack(spacing: theme.spacing) {
                            basicInfoSection
                            backgroundStyleSection
                            doorStyleSection
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
                .fullScreenCover(item: $selectedDoor) { door in
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
            
            // Date selection for daily unlock mode
            if stateManager.model.unlockMode == .daily {
                DatePicker("Start Date",
                          selection: $stateManager.model.startDate,
                          in: ...stateManager.model.endDate,
                          displayedComponents: .date)
                    .font(theme.bodyFont)
                
                DatePicker("End Date",
                          selection: $stateManager.model.endDate,
                          in: stateManager.model.startDate...,
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
    
    // Section for background style selection
    private var backgroundStyleSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing) {
            Text("Background Style")
                .font(theme.headlineFont)
                .foregroundColor(theme.text)
            
            // Background type picker
            Picker("Background Type", selection: $stateManager.model.backgroundType) {
                Text("Image").tag(BackgroundType.image)
                Text("Color").tag(BackgroundType.color)
            }
            .pickerStyle(.segmented)
            
            // Shows color picker or image picker based on selection
            if stateManager.model.backgroundType == .color {
                HStack(alignment: .center) {
                    Text("Select Background Color")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(theme.bodyFont)
                    
                    ColorPicker("Background Color", selection: $stateManager.model.backgroundColor, supportsOpacity: false)
                        .labelsHidden()
                        .onChange(of: stateManager.model.backgroundColor) { _, _ in
                            // Clears the background image when a color is selected
                            stateManager.model.backgroundImageData = nil
                    }
                }
            } else {
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

        }
        .padding(theme.padding)
        .background(theme.secondary)
        .cornerRadius(theme.cornerRadius)
        .onChange(of: selectedImageItem) { _, newValue in
            Task {
                // Tries to load the selected image as transferable data
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    stateManager.model.backgroundImageData = data // Converts the raw data into a UIImage if possible
                    stateManager.model.backgroundType = .image // Switches to image mode when an image is selected
                }
            }
        }
        .onChange(of: stateManager.model.backgroundType) { _, newValue in
            switch newValue {
                case .color:
                    stateManager.model.backgroundImageData = nil // Clears the background image when switching to color mode
                case .image:
                    stateManager.model.backgroundColor = .clear // Clears the background color when switching to image mode
                }
        }
    }
    
    // Section for door style selection
    private var doorStyleSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing) {
            Text("Door Style")
                .font(theme.headlineFont)
                .foregroundColor(theme.text)
            
            HStack(alignment: .center) {
                Text("Select Door Color")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(theme.bodyFont)
                ColorPicker("Door Color", selection: $stateManager.model.doorColor, supportsOpacity: false)
                    .labelsHidden()
            }
        }
        .padding(theme.padding)
        .background(theme.secondary)
        .cornerRadius(theme.cornerRadius)
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
                Text("Doors")
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
    
    // Generates a scrollable grid view of door previews for the calendar editor
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
            .padding(.horizontal, theme.padding.trailing/4)
            .padding(.vertical, theme.padding.leading/4)
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
    
    // Files section that allows users to reset editor, export or delete their calendar or import an external one
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
            
            // Reset Button
            Button(action: {
                stateManager.reset() // Resets the editor state to defaults
                generateDoors()
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset Editor")
                        .font(theme.bodyFont)
                }
                .frame(maxWidth: .infinity)
                .padding(theme.padding)
                .background(theme.accent.opacity(0.4))
                .foregroundColor(theme.accent)
                .cornerRadius(theme.cornerRadius)
            }
            
            // Delete Button
            Button(action: {
                let defaultCalendar = HolidayCalendar.createDefault()
                CalendarStateManager.shared.reset(with: defaultCalendar)
                onSaveCalendar(defaultCalendar)
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Current Calendar")
                        .font(theme.bodyFont)
                }
                .frame(maxWidth: .infinity)
                .padding(theme.padding)
                .background(Color.red.opacity(0.75))
                .foregroundColor(.white)
                .cornerRadius(theme.cornerRadius)
            }
        }
        .padding(theme.padding)
        .background(theme.secondary)
        .cornerRadius(theme.cornerRadius)
    }
    
    // MARK: - Helper Functions
    
    // Saves the current calendar configuration and notifies the parent view
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
        
        // Stores existing door content and unlock dates
        var doorNumberToContent: [Int: DoorContent] = [:]
        var doorNumberToUnlockDate: [Int: Date] = [:]
        for door in stateManager.model.doors {
            doorNumberToContent[door.number] = door.content
            doorNumberToUnlockDate[door.number] = door.unlockDate
        }
        
        let newDoors = (1...stateManager.model.doorCount).map { number in
            let unlockDate: Date
            if stateManager.model.unlockMode == .daily {
                // Sets unlock date to midnight of the corresponding day
                let baseDate = calendar.date(byAdding: .day, value: number - 1, to: stateManager.model.startDate) ?? stateManager.model.startDate
                let components = calendar.dateComponents([.year, .month, .day], from: baseDate)
                unlockDate = calendar.date(from: components) ?? baseDate
            } else {
                // Specific mode: Keep existing unlock date if available, otherwise use sequential dates
                if let existingDate = doorNumberToUnlockDate[number] {
                    // Keeps existing unlock date for edited doors
                    unlockDate = existingDate
                } else {
                    // For new doors, set default sequential dates
                    let baseDate = calendar.date(byAdding: .day, value: number - 1, to: stateManager.model.startDate) ?? stateManager.model.startDate
                    let components = calendar.dateComponents([.year, .month, .day], from: baseDate)
                    unlockDate = calendar.date(from: components) ?? baseDate
                }
            }
            
            // If we have edited content for this door number, use it
            let content = doorNumberToContent[number] ?? .text("Add content for door \(number)")
            
            let isUnlocked = unlockDate <= currentDate
            
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
