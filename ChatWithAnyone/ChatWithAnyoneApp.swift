import SwiftUI

@main
struct ChatWithAnyoneApp: App {
    var body: some Scene {
        WindowGroup {
            if #available(iOS 26.0, *) {
                ContentView()
            } else {
                // Optional: Show a message if running on unsupported iOS versions
                Text("This app requires iOS 26 or newer.")
                    .padding()
                    .font(.headline)
            }
        }
    }
}

