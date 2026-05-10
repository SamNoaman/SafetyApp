import SwiftUI
import SwiftData

@main
struct SOSFamilyAlert: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: Contact.self)
    }
}
