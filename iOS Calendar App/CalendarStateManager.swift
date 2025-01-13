import SwiftUI

// Manages the global state of the calendar
// and handles synchronization between different views (map and calendar)
class CalendarStateManager: ObservableObject {
    static let shared = CalendarStateManager()
    
    // The source of truth for calendar data
    @Published var calendar: HolidayCalendar {
        didSet {
            save() // Saves calendar data whenever it changes
        }
    }
    
    // Weak reference collection of observers to prevent memory leaks
    // Used to track DoorOpeningManager instances that need state updates
    private var observers = NSHashTable<AnyObject>.weakObjects()
    
    private init() {
        // Tries to load saved calendar, or create default one if none exists
        if let savedCalendar = AppStorage.shared.loadCalendar() {
            self.calendar = savedCalendar
        } else {
            self.calendar = HolidayCalendar.createDefault()
        }
    }
    
    // Registers a door manager to receive state updates
    func addObserver(_ observer: AnyObject) {
        observers.add(observer)
    }
    
    // Removes a door manager from receiving updates (called in deinit)
    func removeObserver(_ observer: AnyObject) {
        observers.remove(observer)
    }
    
    // Updates a door's state and synchronizes the change across all views
    // Uses a "silent" update pattern to prevent recursive update cycles
    func silentlyUpdateDoor(_ updatedDoor: CalendarDoor) {
        if let index = calendar.doors.firstIndex(where: { $0.id == updatedDoor.id }) {
            calendar.doors[index] = updatedDoor // Update the master calendar's data
            
            // Notifies only the observers (door managers) that are displaying this specific door
            for case let observer as DoorOpeningManager in observers.allObjects {
                if observer.door.id == updatedDoor.id {
                    observer.door = updatedDoor
                }
            }
            save()
        }
    }
    
    // MARK: - Storage Operations
        
    // Saves the current calendar data
    private func save() {
        try? AppStorage.shared.saveCalendar(calendar)
    }
    
    // Resets the entire calendar state manager with a new calendar
    func reset(with newCalendar: HolidayCalendar) {
        observers.removeAllObjects() // Clear all observers
        calendar = newCalendar
        try? AppStorage.shared.saveCalendar(calendar)
    }
}
