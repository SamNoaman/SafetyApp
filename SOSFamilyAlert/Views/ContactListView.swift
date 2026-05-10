import SwiftUI
import SwiftData

struct ContactListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Contact.createdAt, order: .reverse) private var contacts: [Contact]
    @State private var viewModel = ContactsViewModel()

    var body: some View {
        List {
            if contacts.isEmpty {
                ContentUnavailableView(
                    "No Contacts",
                    systemImage: "person.crop.circle.badge.plus",
                    description: Text("Add contacts to quickly reach them in an emergency.")
                )
            } else {
                ForEach(contacts) { contact in
                    ContactRow(contact: contact)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectedContact = contact
                            viewModel.showActionSheet = true
                        }
                }
                .onDelete { indexSet in
                    let toDelete = indexSet.map { contacts[$0] }
                    viewModel.deleteContacts(toDelete, from: modelContext)
                }
            }
        }
        .navigationTitle("Contacts")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.showAddContact = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .confirmationDialog(
            viewModel.selectedContact?.name ?? "Contact",
            isPresented: $viewModel.showActionSheet,
            titleVisibility: .visible
        ) {
            if let contact = viewModel.selectedContact {
                Button("Call") {
                    viewModel.callContact(contact)
                }
                Button("Message") {
                    viewModel.messageContact(contact)
                }
                Button("Edit") {
                    viewModel.showEditContact = true
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .sheet(isPresented: $viewModel.showAddContact) {
            NavigationStack {
                AddContactView()
            }
        }
        .sheet(isPresented: $viewModel.showEditContact) {
            if let contact = viewModel.selectedContact {
                NavigationStack {
                    AddContactView(existingContact: contact)
                }
            }
        }
    }
}

struct ContactRow: View {
    let contact: Contact

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(contact.name)
                        .font(.headline)
                    if let label = contact.label, !label.isEmpty {
                        Text(label)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.tertiary)
                            .clipShape(Capsule())
                    }
                }
                Text(contact.phone)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if contact.isEmergency {
                Image(systemName: "staroflife.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ContactListView()
    }
    .modelContainer(for: Contact.self, inMemory: true)
}
