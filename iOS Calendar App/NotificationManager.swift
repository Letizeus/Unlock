import Foundation
import UserNotifications

// Handles all local notification-related operations for the app.
class NotificationManager: NSObject, ObservableObject {
    
    static let shared = NotificationManager()
    
    // MARK: - Properties
    
    @Published private(set) var hasPermission = false // Tracks whether the user has granted notification permissions
    private let notificationCenter = UNUserNotificationCenter.current() // Reference to the system's notification center
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
        checkPermissionStatus()
    }
    
    // MARK: - Permission Handling
    
    // Checks the current notification permission status
    // Updates the hasPermission property based on system settings
    private func checkPermissionStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // Requests permission from the user to send notifications
    // Updates hasPermission based on user's choice
    func requestPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.hasPermission = granted
            }
            if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Door Notifications
    
    // Schedules two notifications for a door:
    // 1. A reminder 10 minutes before the door unlocks
    // 2. A notification when the door becomes available
    func scheduleDoorNotifications(for door: CalendarDoor) {
        guard hasPermission else { return }
        
        // Cancels any existing notifications for this door
        cancelDoorNotifications(for: door)
        
        // Schedules "10 minutes before" notification
        let tenMinContent = UNMutableNotificationContent()
        tenMinContent.title = "Holiday Calendar"
        tenMinContent.body = "Door \(door.number) unlocks in 10 minutes!"
        tenMinContent.sound = .default
        
        // Calculates the time 10 minutes before unlock
        let tenMinTriggerDate = Calendar.current.date(
            byAdding: .minute,
            value: -10,
            to: door.unlockDate
        )
        
        // Only schedules the 10-minute warning if it's in the future
        if let tenMinDate = tenMinTriggerDate, tenMinDate > Date() {
            let tenMinTrigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: tenMinDate
                ),
                repeats: false
            )
            
            let tenMinRequest = UNNotificationRequest(
                identifier: "door_\(door.number)_10min",
                content: tenMinContent,
                trigger: tenMinTrigger
            )
            
            notificationCenter.add(tenMinRequest)
        }
        
        // Schedules "door unlock" notification
        let unlockContent = UNMutableNotificationContent()
        unlockContent.title = "Holiday Calendar"
        unlockContent.body = "Door \(door.number) is now available to open!"
        unlockContent.sound = .default
        
        let unlockTrigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: door.unlockDate
            ),
            repeats: false
        )
        
        let unlockRequest = UNNotificationRequest(
            identifier: "door_\(door.number)_unlock",
            content: unlockContent,
            trigger: unlockTrigger
        )
        
        notificationCenter.add(unlockRequest)
    }
    
    // Cancels all notifications associated with a specific door
    func cancelDoorNotifications(for door: CalendarDoor) {
        let identifiers = [
            "door_\(door.number)_10min",
            "door_\(door.number)_unlock"
        ]
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    // Cancels all pending notifications in the app
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
}

// MARK: - Extensions

extension NotificationManager: UNUserNotificationCenterDelegate {
    // Handles notifications when the app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        if #available(iOS 14.0, *) {
            return [.banner, .sound] // For iOS 14 and later, using .banner
        } else {
            return [.alert, .sound] // .alert for earlier iOS versions
        }
    }
    
    // Handles the user's response to a notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
    }
}
