import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Hello, World! Let's go.")
                .font(.title)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
