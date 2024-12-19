import SwiftUI

// MARK: - TabViewEditor


// MARK: - TabViewCalendar

struct CountdownDisplay: View {
    let nextDoorNumber: Int
    let countdown: CountdownInfo
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                CountdownCell(value: countdown.days, label: "days")
                colonSeparator
                CountdownCell(value: countdown.hours, label: "hours")
                colonSeparator
                CountdownCell(value: countdown.minutes, label: "minutes")
            }
            
            Text("until Door \(nextDoorNumber)!")
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
    
    private var colonSeparator: some View {
        Text(":")
            .foregroundStyle(.white)
            .font(.system(size: 24, weight: .bold))
            .offset(y: -8) // Adjust colon position to allign with the numbers
    }
}

// MARK: - TabViewMap


