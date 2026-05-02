import SwiftUI
import SwiftData

struct AddContactView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var existingContact: Contact?

    @State private var name = ""
    @State private var phone = ""
    @State private var label = ""
    @State private var isEmergency = true

    private var isEditing: Bool { existingContact != nil }

    var body: some View {
        Form {
            Section("Contact Info") {
                TextField("Name", text: $name)
                    .textContentType(.name)
                    .autocorrectionDisabled()

                TextField("Phone Number", text: $phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)

                TextField("Label (e.g., Mom, Campus Security)", text: $label)
                    .autocorrectionDisabled()
            }

            Section {
                Toggle("Emergency Contact", isOn: $isEmergency)
            } footer: {
                Text("Emergency contacts will receive your SMS alert with location when you tap the Emergency button.")
            }
        }
        .navigationTitle(isEditing ? "Edit Contact" : "Add Contact")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty ||
                          phone.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            if let contact = existingContact {
                name = contact.name
                phone = contact.phone
                label = contact.label ?? ""
                isEmergency = contact.isEmergency
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespaces)
        let trimmedLabel = label.trimmingCharacters(in: .whitespaces)

        if let contact = existingContact {
            contact.name = trimmedName
            contact.phone = trimmedPhone
            contact.label = trimmedLabel.isEmpty ? nil : trimmedLabel
            contact.isEmergency = isEmergency
        } else {
            let contact = Contact(
                name: trimmedName,
                phone: trimmedPhone,
                label: trimmedLabel.isEmpty ? nil : trimmedLabel,
                isEmergency: isEmergency
            )
            modelContext.insert(contact)
        }
    }
}

#Preview {
    NavigationStack {
        AddContactView()
    }
    .modelContainer(for: Contact.self, inMemory: true)
}
