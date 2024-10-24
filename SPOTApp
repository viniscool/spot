import SwiftUI

@main
struct SPOT: App {
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false

    var body: some Scene {
        WindowGroup {
            SpeechView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
