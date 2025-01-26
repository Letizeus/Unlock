import SwiftUI
import Combine
import SwiftData

// MARK: - DoorOpeningManager
// Manages the state and animations for an individual door
// Each door instance (in both map and calendar view) has its own manager
class DoorOpeningManager: ObservableObject {
    @Published var door: CalendarDoor
    @Published var isShowingContent = false // Controls content sheet presentation
    @Published var doorRotation = 0.0
    @Published var doorOpacity = 1.0
    @Published var isPressed = false
    @Published var hasCompletedOpening = false
    
    @Binding var isAnyDoorOpening: Bool
    
    init(door: CalendarDoor, isAnyDoorOpening: Binding<Bool>) {
        self.door = door
        self._isAnyDoorOpening = isAnyDoorOpening
        
        // Immediately update state on init
        CalendarStateManager.shared.addObserver(self)
    }
    
    func handleDoorTap(completion: @escaping () -> Void) {
        guard door.isUnlocked && !isAnyDoorOpening else { return }
        
        isAnyDoorOpening = true
        
        // Animates door opening
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            doorRotation = 180 // Rotates half turn
            doorOpacity = 0.0 // Fades out door to see content
        }
        
        // Shows content sheet after the door animation
        // Schedules code execution after a delay of 0.5 seconds
        // - Uses the main dispatch queue to ensure UI updates happen on the main thread
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.isShowingContent = true
            self.door.hasBeenOpened = true
            self.door.isUnlocked = true
            
            // Propagates state change to other views
            CalendarStateManager.shared.silentlyUpdateDoor(self.door)
            
            // Resets door after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    self.doorRotation = 0
                    self.doorOpacity = 1.0
                }
                self.isAnyDoorOpening = false
            }
        }
    }
    
    // Cleanup: removes this manager from receiving updates when view is destroyed
    deinit {
        CalendarStateManager.shared.removeObserver(self)
    }
    
    // Checks if the door should be unlocked
    func updateUnlockState() {
        door.isUnlocked = Calendar.current.startOfDay(for: Date()) >= Calendar.current.startOfDay(for: door.unlockDate)
    }
}

// MARK: - DoorInteractionModifier
// Shared view modifier for door interaction
struct DoorInteractionModifier: ViewModifier {
    @ObservedObject var manager: DoorOpeningManager
    let onCompletion: () -> Void
    
    // Computed property for checking if on iPad
    private var onIPad: Bool {
        if (UIDevice.current.userInterfaceIdiom == .pad) {
            return true
        } else {
            return false
        }
    }
    
    func body(content: Content) -> some View {
            content
            .scaleEffect(manager.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: manager.isPressed)
            // Handles tap interaction
            .onTapGesture {
                if manager.door.isUnlocked && !manager.isAnyDoorOpening {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        manager.isPressed = true
                    }
                    // Resets the pressed state after a short delay and trigger door opening
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            manager.isPressed = false
                        }
                        manager.handleDoorTap(completion: onCompletion)
                    }
                }
            }
            // Only allow interaction with unlocked doors
            .allowsHitTesting(manager.door.isUnlocked && !manager.isAnyDoorOpening)
            // Destinctions if iPad to provide view with fullScreenCover instead of sheet
            .if(onIPad) { view in
                // Present content screen cover when door is opened
                view.fullScreenCover(isPresented: $manager.isShowingContent, content: {
                    DoorContentView(
                        content: manager.door.content,
                        door: manager.door,
                        onReactionAdded: handleReactionAdded
                    )
                    .interactiveDismissDisabled()
                })
            }
            .if(!onIPad) { view in
                view.sheet(isPresented: $manager.isShowingContent) {
                    DoorContentView(
                        content: manager.door.content,
                        door: manager.door,
                        onReactionAdded: handleReactionAdded
                    )
                        .interactiveDismissDisabled()
                }
            }
            // Checks unlock state when view appears
            .onAppear {
                manager.updateUnlockState()
            }
    }
    
    // Handles when a user adds a new reaction
    // Updates the door's reactions and propagates the change through CalendarStateManager
    private func handleReactionAdded(_ emoji: String) {
        var updatedDoor = manager.door
        updatedDoor.addReaction(emoji, userId: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString)
        CalendarStateManager.shared.silentlyUpdateDoor(updatedDoor)
    }
}

// MARK: - ViewExtension
// Extension on View to provide a convenient way to add door interaction behavior
// This allows us to use the .doorInteraction() modifier on any view
extension View {
    func doorInteraction(manager: DoorOpeningManager, onCompletion: @escaping () -> Void) -> some View {
        modifier(DoorInteractionModifier(manager: manager, onCompletion: onCompletion))
    }
}
