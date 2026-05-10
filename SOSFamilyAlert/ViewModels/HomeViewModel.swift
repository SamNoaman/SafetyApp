import SwiftUI
import SwiftData
import CoreLocation

@MainActor
@Observable
final class HomeViewModel {
    var showLocationSMS = false
    var showNonEmergencySMS = false
    var showNoContactsAlert = false
    var showCannotSendAlert = false
    var showLocationError = false
    var showEmergencyRecording = false
    var errorMessage = ""

    var messageRecipients: [String] = []
    var messageBody: String = ""

    let locationService = LocationService()

    func handleEmergencyTap(contacts: [Contact]) {
        let emergencyContacts = contacts.filter { $0.isEmergency }

        guard !emergencyContacts.isEmpty else {
            showNoContactsAlert = true
            return
        }

        guard AlertService.canSendMessages() else {
            showCannotSendAlert = true
            return
        }

        messageRecipients = emergencyContacts.map { $0.phone }

        if let coord = locationService.currentCoordinate {
            messageBody = AlertService.buildEmergencyMessage(coordinate: coord)
        } else {
            messageBody = "EMERGENCY ALERT: I need immediate help! (Location being determined) Video evidence to follow."
        }

        showLocationSMS = true
    }

    func handleNonEmergencyTap(contacts: [Contact]) {
        guard !contacts.isEmpty else {
            showNoContactsAlert = true
            return
        }

        guard AlertService.canSendMessages() else {
            showCannotSendAlert = true
            return
        }

        messageRecipients = contacts.map { $0.phone }

        if let coord = locationService.currentCoordinate {
            messageBody = AlertService.buildNonEmergencyMessage(coordinate: coord)
        } else {
            messageBody = "NON-EMERGENCY: I wanted to let you know where I am. (Location being determined) I'm safe but wanted you to have my location."
        }

        showNonEmergencySMS = true
    }

    func handleLocationSMSSent() {
        showLocationSMS = false
        showEmergencyRecording = true
    }

    func handleNonEmergencySMSSent() {
        showNonEmergencySMS = false
    }

    func requestLocationPermission() {
        locationService.requestPermission()
        locationService.startContinuousTracking()
    }
}
