import MessageUI
import SwiftUI
import CoreLocation
import UniformTypeIdentifiers

struct MessageComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String
    var attachmentData: Data? = nil
    var attachmentFilename: String? = nil
    let onFinish: (MessageComposeResult) -> Void

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.recipients = recipients
        controller.body = body
        if let data = attachmentData, let filename = attachmentFilename {
            controller.addAttachmentData(data, typeIdentifier: UTType.movie.identifier, filename: filename)
        }
        controller.messageComposeDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let onFinish: (MessageComposeResult) -> Void

        init(onFinish: @escaping (MessageComposeResult) -> Void) {
            self.onFinish = onFinish
        }

        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true)
            onFinish(result)
        }
    }
}

struct AlertService {
    static func canSendMessages() -> Bool {
        MFMessageComposeViewController.canSendText()
    }

    static func buildEmergencyMessage(coordinate: CLLocationCoordinate2D) -> String {
        let lat = String(format: "%.6f", coordinate.latitude)
        let lng = String(format: "%.6f", coordinate.longitude)

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeString = formatter.string(from: Date())

        return """
        EMERGENCY ALERT: I need immediate help!

        My location as of \(timeString):
        https://maps.apple.com/?ll=\(lat),\(lng)&q=Emergency+Location

        Video evidence is attached.
        """
    }

    static func buildNonEmergencyMessage(coordinate: CLLocationCoordinate2D) -> String {
        let lat = String(format: "%.6f", coordinate.latitude)
        let lng = String(format: "%.6f", coordinate.longitude)

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeString = formatter.string(from: Date())

        return """
        NON-EMERGENCY: I wanted to let you know where I am.

        My location as of \(timeString):
        https://maps.apple.com/?ll=\(lat),\(lng)&q=My+Location

        I'm safe but wanted you to have my location.
        """
    }
}
