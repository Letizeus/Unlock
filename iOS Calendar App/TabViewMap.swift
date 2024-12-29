import SwiftUI

// TabViewMap provides an alternative visualization of the holiday calendar in a vertical,
// journey-style layout. It displays calendar doors as checkpoints along a road,
// creating a path-like progression through the calendar content.
struct TabViewMap: View {
    
    class MapViewModel: ObservableObject {
        @Published var isAnyDoorOpening = false
    }
    
    @Environment(\.mapTheme) private var theme
    
    // MARK: - Properties
    
    let calendar: HolidayCalendar // The calendar data model containing all doors and their content
    
    @StateObject private var viewModel = MapViewModel() // Only one door at once
    
    // MARK: - View Body
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    ZStack {
                        theme.background
                            .ignoresSafeArea()
                        // Base road path - creates a vertical line connecting all checkpoints
                        Rectangle()
                            .fill(theme.roadStyle.color)
                            .frame(width: theme.roadStyle.width)
                            .frame(maxHeight: .infinity)
                        
                        // Vertical stack of checkpoint nodes representing each door
                        LazyVStack(spacing: theme.roadStyle.nodeSpacing) {
                            ForEach(calendar.doors) { door in
                                CheckpointNodeView(
                                    isAnyDoorOpening: $viewModel.isAnyDoorOpening,
                                    door: door
                                )
                            }
                        }
                        // Using geometry ensures consistent spacing proportion
                        // regardless of device size or orientation
                        .padding(.vertical, geometry.size.height/6)
                    }
                }
                // When the view appears, automatically scroll to the current node
                .onAppear {
                    Task { @MainActor in
                        // Small delay to ensure view is ready
                        try? await Task.sleep(for: .milliseconds(300))
                        if let doorToScrollTo = findCurrentNode() {
                            withAnimation {
                                proxy.scrollTo(doorToScrollTo.id, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    // Finds the Node that corresponds to the current date
    private func findCurrentNode() -> CalendarDoor? {
        let today = Calendar.current.startOfDay(for: Date())
        
        return calendar.doors.first { door in
            Calendar.current.isDate(today, inSameDayAs: door.unlockDate)
        }
    }
}

// MARK: - Preview

#Preview {
    TabViewMap(calendar: HolidayCalendar.createDefault())
}
