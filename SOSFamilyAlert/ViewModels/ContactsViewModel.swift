import SwiftUI
import SwiftData

@MainActor
@Observable
final class ContactsViewModel {
    var selectedContact: Contact?
    var showActionSheet = false
    var showAddContact = false
    var showEditContact = false

    func deleteContacts(_ contacts: [Contact], from context: ModelContext) {
        for contact in contacts {
            context.delete(contact)
        }
    }

    func callContact(_ contact: Contact) {
        let cleaned = contact.phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }

    func messageContact(_ contact: Contact) {
        let cleaned = contact.phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        if let url = URL(string: "sms:\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }
}
