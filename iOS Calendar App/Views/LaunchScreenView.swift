import SwiftUI

struct LaunchScreenView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false // Tracks whether the user has completed the onboarding process
    @State private var isActive = false
    
    var body: some View {
        if isActive {
            if hasCompletedOnboarding {
                MainView()
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        } else {
            VStack {
                Image("LaunchIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .cornerRadius(20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .onAppear {
                // Delay of 0.3 second before transitioning
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
