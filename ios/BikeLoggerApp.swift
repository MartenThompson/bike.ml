import SwiftUI

@main
struct BikeLoggerApp: App {
    @StateObject private var viewModel = MotionLoggingViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}

