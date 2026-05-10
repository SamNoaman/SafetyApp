@preconcurrency import AVFoundation
import UIKit

enum CameraError: LocalizedError {
    case permissionDenied
    case cameraUnavailable
    case configurationFailed
    case recordingFailed
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Camera or microphone permission was denied. Please enable access in Settings."
        case .cameraUnavailable:
            return "No camera is available on this device."
        case .configurationFailed:
            return "Failed to configure the camera. Please try again."
        case .recordingFailed:
            return "Video recording failed. Please try again."
        case .saveFailed:
            return "Failed to save video to Photos."
        }
    }
}

@MainActor
final class CameraService: NSObject {
    let captureSession = AVCaptureSession()
    private let movieOutput = AVCaptureMovieFileOutput()
    private let sessionQueue = DispatchQueue(label: "com.safetyapp.camera-session")

    private var onRecordingFinished: ((Result<URL, Error>) -> Void)?
    private var recordingOutputURL: URL?

    var isCurrentlyRecording: Bool {
        movieOutput.isRecording
    }

    func requestPermissions() async -> Bool {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)

        let cameraGranted: Bool
        if cameraStatus == .notDetermined {
            cameraGranted = await AVCaptureDevice.requestAccess(for: .video)
        } else {
            cameraGranted = cameraStatus == .authorized
        }

        let micGranted: Bool
        if micStatus == .notDetermined {
            micGranted = await AVCaptureDevice.requestAccess(for: .audio)
        } else {
            micGranted = micStatus == .authorized
        }

        return cameraGranted && micGranted
    }

    func configureCaptureSession() throws {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        captureSession.sessionPreset = .medium

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraError.cameraUnavailable
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: camera)
            guard captureSession.canAddInput(videoInput) else {
                throw CameraError.configurationFailed
            }
            captureSession.addInput(videoInput)
        } catch let error as CameraError {
            throw error
        } catch {
            throw CameraError.configurationFailed
        }

        if let mic = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: mic),
           captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
        }

        guard captureSession.canAddOutput(movieOutput) else {
            throw CameraError.configurationFailed
        }
        captureSession.addOutput(movieOutput)
    }

    /// Starts the session and waits until it's actually running before returning
    func startSessionAndWait() async {
        await withCheckedContinuation { continuation in
            let session = captureSession
            sessionQueue.async {
                if !session.isRunning {
                    session.startRunning()
                }
                continuation.resume()
            }
        }
    }

    func stopSession() {
        let session = captureSession
        sessionQueue.async {
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    func startRecording() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        recordingOutputURL = tempURL
        movieOutput.startRecording(to: tempURL, recordingDelegate: self)
    }

    func stopRecording(completion: @escaping (Result<URL, Error>) -> Void) {
        if movieOutput.isRecording {
            onRecordingFinished = completion
            movieOutput.stopRecording()
        } else if let url = recordingOutputURL, FileManager.default.fileExists(atPath: url.path) {
            // Recording already finished on its own — return the file
            completion(.success(url))
        } else {
            // No recording happened — send SMS without video
            completion(.failure(CameraError.recordingFailed))
        }
    }
}

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        Task { @MainActor in
            recordingOutputURL = outputFileURL
            if let error {
                onRecordingFinished?(.failure(error))
            } else {
                onRecordingFinished?(.success(outputFileURL))
            }
            onRecordingFinished = nil
        }
    }
}
