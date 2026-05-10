import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var contacts: [Contact]
    @State private var viewModel = HomeViewModel()
    @State private var showManageContacts = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 60))
                        .foregroundStyle(.primary)
                    Text("SOS Family Alert")
                        .font(.largeTitle.bold())
                    Text("Stay safe, stay connected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 60)

                VStack(spacing: 24) {
                    Button3D(
                        label: "Emergency",
                        icon: "exclamationmark.triangle.fill",
                        color: .red
                    ) {
                        viewModel.handleEmergencyTap(contacts: contacts)
                    }

                    Button3D(
                        label: "Non-Emergency",
                        icon: "phone.fill",
                        color: .blue
                    ) {
                        viewModel.handleNonEmergencyTap(contacts: contacts)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                Button {
                    showManageContacts = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.2.fill")
                        Text("Manage Contacts")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.bottom, 32)
            }
            .navigationDestination(isPresented: $showManageContacts) {
                ContactListView()
            }
            // Emergency SMS with location
            .sheet(isPresented: $viewModel.showLocationSMS) {
                MessageComposeView(
                    recipients: viewModel.messageRecipients,
                    body: viewModel.messageBody
                ) { _ in
                    viewModel.handleLocationSMSSent()
                }
            }
            // Non-Emergency SMS with location
            .sheet(isPresented: $viewModel.showNonEmergencySMS) {
                MessageComposeView(
                    recipients: viewModel.messageRecipients,
                    body: viewModel.messageBody
                ) { _ in
                    viewModel.handleNonEmergencySMSSent()
                }
            }
            // Video recording (after emergency SMS sent)
            .fullScreenCover(isPresented: $viewModel.showEmergencyRecording) {
                EmergencyRecordingView(
                    emergencyContacts: contacts.filter { $0.isEmergency },
                    onDismiss: {
                        viewModel.showEmergencyRecording = false
                    }
                )
            }
            .alert("No Contacts", isPresented: $viewModel.showNoContactsAlert) {
                Button("Add Contacts") {
                    showManageContacts = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please add at least one contact before sending an alert.")
            }
            .alert("Cannot Send Messages", isPresented: $viewModel.showCannotSendAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This device is not configured to send SMS messages. Please check your settings.")
            }
            .onAppear {
                viewModel.requestLocationPermission()
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Contact.self, inMemory: true)
}
