import SwiftUI

struct CalendarView: View {
    
    // MARK: - Properties
    
    // The calendar data model containing all doors and their content
    @State private var calendar: HolidayCalendar
    // Currently selected tab in the main navigation
    @State private var selectedTab = Tab.calendar
    
    @State private var days = 0
    @State private var hours = 0
    @State private var minutes = 0
    
    // Timer that updates the countdown every second
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // MARK: - Initialization
    
    init(calendar: HolidayCalendar) {
        _calendar = State(initialValue: calendar)
    }
    
    // MARK: - View Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Calendar View
            NavigationStack {
                ZStack {
                    // Background color
                    Color(UIColor.systemIndigo)
                        .opacity(0.9)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        // Countdown display for next available door
                        if let nextDoor = findNextDoor() {
                            VStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    CountdownCell(value: days, label: "days")
                                    Text(":")
                                        .foregroundStyle(.white)
                                        .font(.system(size: 24, weight: .bold))
                                        .offset(y: -8) // Adjust colon position to allign with the numbers
                                    CountdownCell(value: hours, label: "hours")
                                    Text(":")
                                        .foregroundStyle(.white)
                                        .font(.system(size: 24, weight: .bold))
                                        .offset(y: -8) // Adjust colon position to allign with the numbers
                                    CountdownCell(value: minutes, label: "minutes")
                                }
                                
                                Text("until Door \(nextDoor.number)!")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 16))
                            }
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.white.opacity(0.1))
                            }
                            .padding(.horizontal)
                        }
                        
                        // Calendar grid showing all doors
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(1...24, id: \.self) { number in
                                    DoorView(door: calendar.doors[number - 1])
                                        .contentShape(Rectangle()) // Ensures the entire door area is tappable
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .tag(Tab.calendar)
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            
            // Map View
            NavigationStack {
                MapOverview(calendar: calendar)
            }
            .tag(Tab.map)
            .tabItem {
                Label("Map", systemImage: "map")
            }
            
            // Editor View
            NavigationStack {
                ProfileView()
            }
            .tag(Tab.editor)
            .tabItem {
                Label("Editor", systemImage: "pencil")
            }
        }
        .onAppear {
            updateCountdown()
        }
        .onReceive(timer) { _ in
            updateCountdown()
        }
    }
    
    // MARK: - Helper Methods
    
    // Finds the next unopened door that can be unlocked
    private func findNextDoor() -> CalendarDoor? {
        return calendar.doors
            .filter { !$0.isUnlocked && $0.unlockDate > Date() }
            .min { $0.unlockDate < $1.unlockDate }
    }
    
    // Updates the countdown timer values
    private func updateCountdown() {
        guard let nextDoor = findNextDoor() else {
            days = 0
            hours = 0
            minutes = 0
            return
        }
        
        let components = Calendar.current.dateComponents(
            [.day, .hour, .minute], 
            from: Date(),
            to: nextDoor.unlockDate
        )
        
        days = components.day ?? 0
        hours = components.hour ?? 0
        minutes = components.minute ?? 0
    }
}

// MARK: - Tab Views

struct MapOverview: View {
    let calendar: HolidayCalendar
    
    var body: some View {
        VStack {
            Text("Map View")
                .font(.title)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemIndigo).opacity(0.9))
    }
}

struct ProfileView: View {
    var body: some View {
        VStack {
            Text("Editor View")
                .font(.title)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemIndigo).opacity(0.9))
    }
}

// MARK: - Preview

// Creates a sample holiday calendar for preview
// Each door is configured with a unlock date and sample text content
struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView(calendar: createPreviewCalendar())
    }
    
    static func createPreviewCalendar() -> HolidayCalendar {
        let dates = (1...24).map { day -> Date in
            let components = DateComponents(
                year: 2024,
                month: 12,
                day: day
            )
            return Calendar.current.date(from: components) ?? Date()
        }
        
        let doors = dates.enumerated().map { (index, date) in
            CalendarDoor(
                number: index + 1,
                unlockDate: date,
                isUnlocked: date < Date(),
                content: .text("Content for door \(index + 1)")
            )
        }
        
        return HolidayCalendar(
            title: "Calendar 2024",
            startDate: dates.first ?? Date(),
            endDate: dates.last ?? Date(),
            doors: doors
        )
    }
}
