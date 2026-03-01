import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Training") {
                    TrainingView()
                }
                NavigationLink("Operation") {
                    OperationView()
                }
            }
            .navigationTitle("Bike Tracking")
        }
    }
}

#Preview {
    ContentView()
}
