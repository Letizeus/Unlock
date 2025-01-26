import SwiftUI

// TabViewMap provides an alternative visualization of the holiday calendar in a vertical,
// journey-style layout. It displays calendar doors as checkpoints along a road,
// creating a path-like progression through the calendar content.
struct TabViewMap: View {
    
    @Environment(\.mapTheme) private var theme
    
    // MARK: - Properties
    
    @State private var isAnyDoorOpening = false // Only one door at once
    
    let calendar: HolidayCalendar // The calendar data model containing all doors and their content
    
    var nodeNumber: Int { calendar.doors.count }
    
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

                        // Vertical stack of checkpoint nodes representing each door
                        LazyVStack(spacing: theme.roadStyle.nodeSpacing) {
                            ForEach(calendar.doors) { door in
                                CheckpointNodeView(
                                    isAnyDoorOpening: $isAnyDoorOpening,
                                    door: door
                                )
                            }
                        }
                        // Using geometry ensures consistent spacing proportion
                        // regardless of device size or orientation
                        .padding(.vertical, geometry.size.height/6)
                    }
                }
                .scrollIndicators(.hidden)
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
    
    private func randomXPosition(in width: CGFloat) -> CGFloat {
        return CGFloat.random(in: 50...(width-50))
    }
    
    private func pathCurvePoint(from start: CGPoint, to end: CGPoint) -> CGPoint {
        let midX = (start.x + end.x) / 2
        let midY = (start.y + end.y) / 2
        return CGPoint(
            x: midX + CGFloat.random(in: -50...50),
            y: midY + CGFloat.random(in: -50...50)
        )
    }
}

// MARK: - Preview

#Preview {
    TabViewMap(calendar: HolidayCalendar.createDefault())
}
