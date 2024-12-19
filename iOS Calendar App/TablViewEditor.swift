import SwiftUI
import PhotosUI

// Main view for creating and editing holiday calendars.
// Allows users to configure calendar settings, add content, and preview the result.
struct TabViewEditor: View {
    // MARK: - Properties
    
    // Basic Calendar Settings
    @State private var calendarTitle = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(24 * 60 * 60 * 31) // 31 days ahead
    @State private var doorCount = Constants.Calendar.defaultDoorCount
    @State private var gridColumns = 4
    @State private var unlockMode: UnlockMode = .daily
    
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
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0 + 1
    }
    
    let onSaveCalendar: (HolidayCalendar) -> Void
    
    // MARK: - View Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundLayer
                
                ScrollView {
                    VStack(spacing: 20) {
                        basicInfoSection
                        backgroundImageSection
                        previewSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Create Calendar")
            .sheet(isPresented: $isPreviewActive) {
                calendarPreview
            }
            .sheet(isPresented: $isEditingDoor) {
                if let door = selectedDoor {
                    doorEditor(door: door)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                        saveButton
                }
                ToolbarItem(placement: .topBarLeading) {
                        previewButton
                }
            }
            .onAppear(perform: generateDoors)
            .onChange(of: startDate) { _, _ in
                updateDoorCountIfNeeded()
            }
            .onChange(of: endDate) { _, _ in
                updateDoorCountIfNeeded()
            }
            .onChange(of: doorCount) { _, _ in
                if unlockMode == .specific {
                    generateDoors()
                }
            }
            .onChange(of: unlockMode) { _, _ in
                generateDoors()
            }
        }
    }
    
    // MARK: - UI Components
    
    // Background layer for the entire view
    private var backgroundLayer: some View {
        Color(UIColor.systemBackground)
            .ignoresSafeArea()
    }
    
    private var saveButton: some View {
        Button(action: saveCalendar) {
            Text("Save & Use")
        }
        .disabled(calendarTitle.isEmpty || doors.isEmpty)
    }
    
    // Section for basic calendar information input
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.headline)
            
            TextField("Calendar Title", text: $calendarTitle)
                .textFieldStyle(.roundedBorder)
            
            // Unlock mode selection
            Picker("Unlock Mode", selection: $unlockMode) {
                Text(UnlockMode.daily.description).tag(UnlockMode.daily)
                Text(UnlockMode.specific.description).tag(UnlockMode.specific)
            }
            .pickerStyle(.segmented)
            
            // Date selection for daily unlock mode
            if unlockMode == .daily {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
            }
            
            // Always show the stepper, but disable it in daily mode
            Stepper("Number of Doors: \(unlockMode == .daily ? daysBetweenDates : doorCount)",
                   value: $doorCount,
                   in: 1...Constants.Calendar.maxDoorCount)
                .disabled(unlockMode == .daily)
            
            HStack {
                Text("Grid Columns:")
                Stepper("\(gridColumns)", value: $gridColumns, in: 2...Constants.Calendar.maxGridColumns)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Constants.Colors.secondaryBackground)
        .cornerRadius(Constants.UI.defaultCornerRadius)
    }
    
    // Section for background image selection
    private var backgroundImageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Background Image")
                .font(.headline)
            
            PhotosPicker(selection: $selectedImageItem, matching: .images) {
                if let selectedBackgroundImage {
                    Image(uiImage: selectedBackgroundImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: Constants.UI.imagePreviewHeight)
                        .cornerRadius(Constants.UI.defaultCornerRadius)
                } else {
                    Label("Select Image", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                        .frame(height: Constants.UI.imagePreviewHeight / 2)
                        .background(Constants.Colors.tertiaryBackground)
                        .cornerRadius(Constants.UI.defaultCornerRadius)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Constants.Colors.secondaryBackground)
        .cornerRadius(Constants.UI.defaultCornerRadius)
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
        }
        .disabled(doors.isEmpty)
    }
    
    // Section showing door preview grid
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preview")
                .font(.headline)
            
            if doors.isEmpty {
                Text("Add doors to see preview")
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(Constants.Colors.secondaryText)
            } else {
                ScrollView {
                    let columns = Array(repeating: GridItem(.flexible(), spacing: Constants.UI.defaultSpacing),
                                      count: gridColumns)
                    LazyVGrid(columns: columns, spacing: Constants.UI.defaultSpacing) {
                        ForEach(doors) { door in
                            DoorPreviewCell(door: door)
                                .onTapGesture {
                                    selectedDoor = door
                                    isEditingDoor = true
                                }
                        }
                    }
                }
                .frame(maxHeight: Constants.UI.previewMaxHeight)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Constants.Colors.secondaryBackground)
        .cornerRadius(Constants.UI.defaultCornerRadius)
    }
    
    // Full calendar preview view
    private var calendarPreview: some View {
        TabViewCalendar(calendar: createPreviewCalendar())
    }
    
    // MARK: - Helper Methods
    
    private func saveCalendar() {
        let calendar = createPreviewCalendar()
        onSaveCalendar(calendar)
    }
    
    private func updateDoorCountIfNeeded() {
        if unlockMode == .daily {
            doorCount = daysBetweenDates
            generateDoors()
        }
    }
    
    // Generates door entries based on current settings
    private func generateDoors() {
        let calendar = Calendar.current
        
        doors = (1...doorCount).map { number in
            let unlockDate = unlockMode == .daily
                ? calendar.date(byAdding: .day, value: number - 1, to: startDate) ?? startDate
                : startDate // For specific mode, default to start date
            
            return CalendarDoor(
                number: number,
                unlockDate: unlockDate,
                isUnlocked: unlockDate <= Date(),
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
    
    // Creates a door editor view for the specified door
    private func doorEditor(door: CalendarDoor) -> some View {
        NavigationStack {
            DoorViewEditor(door: door, unlockMode: unlockMode) { updatedDoor in
                if let index = doors.firstIndex(where: { $0.id == updatedDoor.id }) {
                    doors[index] = updatedDoor
                }
                isEditingDoor = false
            }
        }
    }
}

// MARK: - Preview Provider

#Preview {
    TabViewEditor { _ in }
}
