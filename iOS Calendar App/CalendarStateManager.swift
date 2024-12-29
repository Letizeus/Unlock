import SwiftUI

// Manages the global state of the calendar
// and handles synchronization between different views (map and calendar)
class CalendarStateManager: ObservableObject {
    static let shared = CalendarStateManager()
    
    @Published var calendar: HolidayCalendar // The source of truth for calendar data
    
    // Weak reference collection of observers to prevent memory leaks
    // Used to track DoorOpeningManager instances that need state updates
    private var observers = NSHashTable<AnyObject>.weakObjects()
    
    private init() {
        self.calendar = HolidayCalendar.createDefault()
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
            
            // Notify only the observers (door managers) that are displaying this specific door
            for case let observer as DoorOpeningManager in observers.allObjects {
                if observer.door.id == updatedDoor.id {
                    observer.door = updatedDoor
                }
            }
        }
    }
}
