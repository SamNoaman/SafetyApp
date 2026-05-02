import SwiftUI
import SwiftData

@main
struct SafetyApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: Contact.self)
    }
}
