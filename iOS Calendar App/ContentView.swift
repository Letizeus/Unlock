import SwiftUI

struct ContentView: View {
    
    @State private var now = Date()
    private let christmas = Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 25))!
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var remainingTime: (days: Int, hours: Int, minutes: Int, seconds: Int) {
        let diff = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: now, to: christmas)
        return (days: diff.day ?? 0, hours: diff.hour ?? 0, minutes: diff.minute ?? 0, seconds: diff.second ?? 0)
    }
    
    var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: now)
    }
    
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ZStack {
            Color.blue.ignoresSafeArea()
            VStack(spacing: 16) {
                HStack {
                    Text("Holiday Calendar")
                        .font(.title)
                        .foregroundColor(.white)
                    Spacer()
                    VStack {
                        Text(currentDateString)
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(8)
                    }
                }
                .padding()
                VStack {
                    Text("Festive Countdown Unleashed:")
                        .font(.headline)
                        .foregroundColor(.white)
                    HStack(spacing: 8) {
                        Text("\(remainingTime.days)")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        Text(":")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        Text(String(format: "%02d", remainingTime.hours))
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        Text(":")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        Text(String(format: "%02d", remainingTime.minutes))
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        Text(":")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        Text(String(format: "%02d", remainingTime.seconds))
                            .font(.largeTitle)
                            .foregroundColor(.white)
                    }
                    Text("to Christmas!")
                        .font(.callout)
                        .foregroundColor(.white)
                }
                .padding()
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(1..<16) { day in
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white)
                                    .frame(height: 100)
                                Text("\(day)")
                                    .font(.largeTitle)
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .onReceive(timer) { _ in
            now = Date()
        }
    }
}

#Preview {
    ContentView()
}
