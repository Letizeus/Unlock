import SwiftUI

struct TabViewCalendar: View {
    
    // MARK: - Properties
    
    // The calendar data model containing all doors and their content
    @State private var calendar: HolidayCalendar
    
    @State private var countdown = CountdownInfo()
    // Timer that updates the countdown every second
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private let doorGridCount: Int = 4
    
    // MARK: - Initialization
    
    init(calendar: HolidayCalendar) {
        _calendar = State(initialValue: calendar)
    }
    
    // MARK: - View Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundLayer
                VStack(spacing: 16) {
                    countdownView
                    doorGrid
                }
            }
        }
        .onAppear(perform: updateCountdown)
        .onReceive(timer) { _ in
            updateCountdown()
        }
    }
    
    private var backgroundLayer: some View {
        Color(UIColor.systemIndigo)
            .opacity(0.9)
            .ignoresSafeArea()
    }
    
    private var countdownView: some View {
        Group {
            if let nextDoor = findNextDoor() {
                CountdownDisplay(
                    nextDoorNumber: nextDoor.number,
                    countdown: countdown
                )
            }
        }
    }
    
    private var doorGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: doorGridCount),
                spacing: 8
            ) {
                ForEach(calendar.doors) { door in
                    DoorView(door: door)
                }
            }
            .padding()
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
    func updateCountdown() {
        guard let nextDoor = findNextDoor() else {
            countdown = CountdownInfo()
            return
        }
        
        let components = Calendar.current.dateComponents(
            [.day, .hour, .minute],
            from: Date(),
            to: nextDoor.unlockDate
        )
        
        countdown = CountdownInfo(
            days: components.day ?? 0,
            hours: components.hour ?? 0,
            minutes: components.minute ?? 0
        )
    }
}

// MARK: - Preview

#Preview {
    TabViewCalendar(calendar: HolidayCalendar.createDefault())
}
