import AVFoundation
import CoreLocation
import Photos
import SwiftUI

enum RecordingState {
    case idle
    case recording
    case stopping
    case readyToSend
}

@MainActor
@Observable
final class EmergencyRecordingViewModel {
    var state: RecordingState = .idle
    var showMessageComposer = false
    var showError = false
    var errorMessage = ""
    var elapsedSeconds = 0

    var messageRecipients: [String] = []
    var messageBody: String = ""
    var videoAttachmentData: Data?
    var videoAttachmentFilename: String?

    let cameraService = CameraService()
    let locationService = LocationService()
    private var timerTask: Task<Void, Never>?
    private var recordedVideoURL: URL?

    var emergencyContacts: [Contact] = []
    var onDismiss: (() -> Void)?

    var isActive: Bool {
        state == .recording || state == .stopping || state == .readyToSend
    }

    func beginEmergencyFlow() async {
        guard await cameraService.requestPermissions() else {
            errorMessage = CameraError.permissionDenied.localizedDescription
            showError = true
            return
        }

        do {
            try cameraService.configureCaptureSession()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return
        }

        // Wait for session to actually be running before recording
        await cameraService.startSessionAndWait()
        cameraService.startRecording()
        state = .recording
        startTimer()

        locationService.requestPermission()
        locationService.startContinuousTracking()
    }

    func stopRecording() {
        guard state == .recording else { return }
        state = .stopping
        timerTask?.cancel()
        timerTask = nil

        let latestCoordinate = locationService.getLatestCoordinate()
        locationService.stopContinuousTracking()

        cameraService.stopRecording { [weak self] result in
            guard let self else { return }

            self.cameraService.stopSession()
            self.messageRecipients = self.emergencyContacts.map { $0.phone }

            switch result {
            case .success(let videoURL):
                self.recordedVideoURL = videoURL

                if let data = try? Data(contentsOf: videoURL) {
                    self.videoAttachmentData = data
                    self.videoAttachmentFilename = "emergency_\(Int(Date().timeIntervalSince1970)).mov"
                }

                if let coordinate = latestCoordinate {
                    self.messageBody = "Emergency video evidence. My location: https://maps.apple.com/?ll=\(String(format: "%.6f", coordinate.latitude)),\(String(format: "%.6f", coordinate.longitude))&q=Emergency+Location"
                } else {
                    self.messageBody = "Emergency video evidence attached."
                }

                self.state = .readyToSend
                self.showMessageComposer = true

                Task.detached {
                    let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                    guard status == .authorized || status == .limited else { return }
                    try? await PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                    }
                }

            case .failure:
                // Video failed but still send SMS with location
                if let coordinate = latestCoordinate {
                    self.messageBody = "EMERGENCY ALERT: I need immediate help! My location: https://maps.apple.com/?ll=\(String(format: "%.6f", coordinate.latitude)),\(String(format: "%.6f", coordinate.longitude))&q=Emergency+Location"
                } else {
                    self.messageBody = "EMERGENCY ALERT: I need immediate help!"
                }

                self.state = .readyToSend
                self.showMessageComposer = true
            }
        }
    }

    func handleMessageFinished() {
        showMessageComposer = false
        cleanup()
        onDismiss?()
    }

    func handleErrorDismissed() {
        cleanup()
        onDismiss?()
    }

    func cleanup() {
        timerTask?.cancel()
        timerTask = nil
        locationService.stopContinuousTracking()
        cameraService.stopSession()
        if let url = recordedVideoURL {
            try? FileManager.default.removeItem(at: url)
            recordedVideoURL = nil
        }
        videoAttachmentData = nil
        state = .idle
    }

    private let maxRecordingSeconds = 120

    private func startTimer() {
        elapsedSeconds = 0
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if !Task.isCancelled {
                    elapsedSeconds += 1
                    if elapsedSeconds >= maxRecordingSeconds {
                        stopRecording()
                        return
                    }
                }
            }
        }
    }

    var formattedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
