import Foundation
import SwiftData

@Model
final class Contact {
    var name: String
    var phone: String
    var label: String?
    var isEmergency: Bool
    var createdAt: Date

    init(name: String, phone: String, label: String? = nil, isEmergency: Bool = true, createdAt: Date = .now) {
        self.name = name
        self.phone = phone
        self.label = label
        self.isEmergency = isEmergency
        self.createdAt = createdAt
    }
}
