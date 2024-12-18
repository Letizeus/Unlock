import SwiftUI

// Reusable view component for displaying a countdown value and its label
struct CountdownCell: View {
    let value: Int
    let label: String // Label describing the value (e.g., "days", "hours")
    
    var body: some View {
        VStack(spacing: 2) {
            Text(String(format: "%02d", value)) // Add leading zero
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(width: 60)
    }
}
