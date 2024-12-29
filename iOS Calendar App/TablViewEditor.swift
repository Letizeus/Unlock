import SwiftUI
import PhotosUI

// Main view for creating and editing holiday calendars.
// Allows users to configure calendar settings, add content, and preview the result.
struct TabViewEditor: View {
    
    @Environment(\.editorTheme) private var theme // Access the editor theme from the environment
    
    // MARK: - Properties
    
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
        Button(action: saveCalendar) {
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
            TextField("Calendar Title", text: $calendarTitle)
                .textFieldStyle(.roundedBorder)
                .font(theme.bodyFont)
            
            // Unlock mode selection
            Picker("Unlock Mode", selection: $unlockMode) {
                Text(UnlockMode.daily.description).tag(UnlockMode.daily)
                Text(UnlockMode.specific.description).tag(UnlockMode.specific)
            }
            .pickerStyle(.segmented)
            
            VStack(alignment: .leading) {
                Text("Layout Style (not working)")
                    .font(theme.bodyFont)
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
            Text("Preview")
                .font(theme.headlineFont)
                .foregroundColor(theme.text)
            
            if doors.isEmpty {
                HStack {
                    Text("Add doors to see preview")
                        .foregroundColor(theme.text.opacity(0.6))
                        .font(theme.bodyFont)
                    Spacer()
                }
            } else {
                ScrollView {
                    let columns = Array(repeating: GridItem(.flexible(), spacing: theme.spacing), count: gridColumns)
                    LazyVGrid(columns: columns, spacing: theme.spacing) {
                        ForEach(doors) { door in
                            DoorPreviewCell(door: door)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedDoor = door
                                }
                        }
                    }
                }
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
    
    // MARK: - Helper Functions
    
    // Saves the current calendar configuration
    private func saveCalendar() {
        let calendar = createPreviewCalendar()
        onSaveCalendar(calendar)
    }
    
    // Generates door entries based on current settings
    private func generateDoors() {
        let calendar = Calendar.current
        
        // Updates door count based on date range in daily mode
        if unlockMode == .daily {
            doorCount = daysBetweenDates
        }
        
        doors = (1...doorCount).map { number in
            let unlockDate = unlockMode == .daily
                ? calendar.date(byAdding: .day, value: number - 1, to: startDate) ?? startDate
                : startDate // For specific mode, default to start date
                
            return CalendarDoor(
                number: number,
                unlockDate: unlockDate,
                isUnlocked: false,
                content: .text("Add content for door \(number)"),
                hasBeenOpened: false
            )
        }
    }

    // Creates a preview calendar instance with current settings
    private func createPreviewCalendar() -> HolidayCalendar {
        let backgroundData = selectedBackgroundImage?.jpegData(compressionQuality: 1.0)
        
        return HolidayCalendar(
            title: calendarTitle.isEmpty ? "Preview Calendar" : calendarTitle,
            startDate: startDate,
            endDate: endDate,
            doors: doors,
            gridColumns: gridColumns,
            backgroundImageData: backgroundData
        )
    }
}

// MARK: - Preview Provider

#Preview {
    TabViewEditor { _ in }
}
