import SwiftUI
import SwiftData

@main
struct CalendarApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            CalendarView(calendar: createCalendar()) // Main holiday calendar
        }
        .modelContainer(sharedModelContainer)
    }
    
    // Creates a holiday calendar
    // Each door is configured with an unlock date and content
    private func createCalendar() -> HolidayCalendar {
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
