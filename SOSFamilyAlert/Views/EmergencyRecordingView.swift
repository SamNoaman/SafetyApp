import SwiftUI
import MapKit

struct EmergencyRecordingView: View {
    @State private var viewModel = EmergencyRecordingViewModel()
    @State private var pulseAnimation = false
    @State private var isMapExpanded = false

    let emergencyContacts: [Contact]
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            CameraPreviewView(session: viewModel.cameraService.captureSession)
                .ignoresSafeArea()

            if viewModel.isActive {
                VStack {
                    HStack(alignment: .top) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(.red)
                                .frame(width: 12, height: 12)
                                .opacity(pulseAnimation ? 0.3 : 1.0)
                                .animation(
                                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                    value: pulseAnimation
                                )
                            Text(viewModel.formattedTime)
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.6), in: Capsule())

                        Spacer()

                        if viewModel.state == .stopping {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.7)
                                Text("SENDING...")
                                    .font(.caption.bold())
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.orange.opacity(0.8), in: Capsule())
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                Text("LIVE")
                                    .font(.caption.bold())
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.red.opacity(0.8), in: Capsule())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)

                    Spacer()

                    LiveMapOverlay(
                        locationService: viewModel.locationService,
                        isExpanded: $isMapExpanded
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                    // Stop button — only while recording
                    if viewModel.state == .recording {
                        Button {
                            viewModel.stopRecording()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 72, height: 72)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.red)
                                    .frame(width: 28, height: 28)
                            }
                        }
                        .padding(.bottom, 40)
                    } else {
                        Spacer().frame(height: 112)
                    }
                }
            }
        }
        .task {
            viewModel.emergencyContacts = emergencyContacts
            viewModel.onDismiss = onDismiss
            pulseAnimation = true
            await viewModel.beginEmergencyFlow()
        }
        .sheet(isPresented: $viewModel.showMessageComposer) {
            MessageComposeView(
                recipients: viewModel.messageRecipients,
                body: viewModel.messageBody,
                attachmentData: viewModel.videoAttachmentData,
                attachmentFilename: viewModel.videoAttachmentFilename
            ) { _ in
                viewModel.handleMessageFinished()
            }
        }
        .alert("Camera Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.handleErrorDismissed()
            }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

struct LiveMapOverlay: View {
    @ObservedObject var locationService: LocationService
    @Binding var isExpanded: Bool

    @State private var mapCameraPosition: MapCameraPosition = .automatic

    private var mapHeight: CGFloat {
        isExpanded ? 300 : 140
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "map.fill")
                        .font(.caption)
                    Text("Real-Time Location")
                        .font(.caption.bold())
                    Spacer()
                    if let coord = locationService.currentCoordinate {
                        Text("\(coord.latitude, specifier: "%.4f"), \(coord.longitude, specifier: "%.4f")")
                            .font(.system(.caption2, design: .monospaced))
                    }
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.caption2.bold())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.black.opacity(0.7))
            }

            Map(position: $mapCameraPosition) {
                if let coord = locationService.currentCoordinate {
                    Annotation("You", coordinate: coord) {
                        ZStack {
                            Circle()
                                .fill(.blue.opacity(0.2))
                                .frame(width: 44, height: 44)
                            Circle()
                                .fill(.blue)
                                .frame(width: 16, height: 16)
                            Circle()
                                .stroke(.white, lineWidth: 3)
                                .frame(width: 16, height: 16)
                        }
                    }
                }
            }
            .mapStyle(.standard)
            .frame(height: mapHeight)
            .allowsHitTesting(isExpanded)
            .onChange(of: locationService.currentCoordinate?.latitude) {
                updateCamera()
            }
            .onChange(of: locationService.currentCoordinate?.longitude) {
                updateCamera()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.4), radius: 8)
        .onAppear {
            updateCamera()
        }
    }

    private func updateCamera() {
        if let coord = locationService.currentCoordinate {
            withAnimation(.easeInOut(duration: 0.5)) {
                mapCameraPosition = .region(MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                ))
            }
        }
    }
}
