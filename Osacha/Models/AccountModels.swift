//
//  AccountModels.swift
//  Osacha
//
//  Data behind the account section: the signed-in profile, saved addresses,
//  payment methods, past orders, notifications, and app preferences.
//

import Foundation
import SwiftUI

struct UserProfile: Codable, Equatable {
    var fullName: String
    var mobileNumber: String
    var address: String

    /// Leading word of the full name, for greetings that address the customer.
    var firstName: String {
        fullName.split(separator: " ").first.map(String.init) ?? fullName
    }

    static let sample = UserProfile(
        fullName: "Mikaela Denise Balasoto",
        mobileNumber: "+63 917 123 4567",
        address: "123 Rizal Street, Brgy. San Isidro, Quezon City"
    )
}

struct SavedAddress: Identifiable, Codable, Equatable {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case home = "Home"
        case work = "Work"
        case other = "Other"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .work: return "building.2.fill"
            case .other: return "mappin.and.ellipse"
            }
        }
    }

    var id = UUID()
    var kind: Kind
    var street: String
    var barangay: String
    var city: String
    var notes: String = ""

    var oneLine: String {
        [street, barangay, city].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    static let samples: [SavedAddress] = [
        SavedAddress(kind: .home, street: "123 Rizal Street", barangay: "Brgy. San Isidro",
                     city: "Quezon City", notes: "Ring the bell twice"),
        SavedAddress(kind: .work, street: "45 Ayala Avenue", barangay: "Brgy. Bel-Air",
                     city: "Makati City", notes: "Leave with the front desk")
    ]
}

struct PaymentMethod: Identifiable, Codable, Equatable {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case card = "Card"
        case gcash = "GCash"
        case maya = "Maya"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .card: return "creditcard.fill"
            case .gcash, .maya: return "wallet.pass.fill"
            }
        }
    }

    var id = UUID()
    var kind: Kind
    var title: String
    var subtitle: String

    static let samples: [PaymentMethod] = [
        PaymentMethod(kind: .card, title: "Visa •••• 4821", subtitle: "Expires 08/27"),
        PaymentMethod(kind: .gcash, title: "GCash", subtitle: "balasotomikaela@gmail.com")
    ]
}

enum OrderStatus: String {
    case preparing = "Preparing"
    case ready = "Ready for pickup"
    case completed = "Completed"
}

struct PastOrder: Identifiable, Codable {
    var id = UUID()
    var reference: String
    var placedAt: String
    var itemCount: Int
    var total: Double

    /// When the order was actually placed. Optional because the seeded history
    /// predates the app and carries only a preformatted string — and because
    /// orders persisted before this field existed must still decode.
    var placedDate: Date?

    var summary: String {
        "\(itemCount) item\(itemCount == 1 ? "" : "s") · \(total.asPHP)"
    }

    /// Derived from how long ago the order was placed, so a drink ordered
    /// seconds ago isn't reported as already finished. Orders with no real
    /// date behind them are historical, so they read as completed.
    var status: OrderStatus {
        guard let placedDate else { return .completed }
        switch Date().timeIntervalSince(placedDate) {
        case ..<Self.preparingDuration: return .preparing
        case ..<Self.readyDuration: return .ready
        default: return .completed
        }
    }

    /// How long a new order spends in each stage before moving on.
    static let preparingDuration: TimeInterval = 5 * 60
    static let readyDuration: TimeInterval = 20 * 60

    static let samples: [PastOrder] = [
        PastOrder(reference: "A1042", placedAt: "Today, 3:15 PM", itemCount: 3, total: 870),
        PastOrder(reference: "A0998", placedAt: "Sep 4, 11:20 AM", itemCount: 2, total: 450),
        PastOrder(reference: "A0951", placedAt: "Aug 28, 4:05 PM", itemCount: 1, total: 255)
    ]
}

struct AppNotification: Identifiable, Codable {
    var id = UUID()
    var icon: String
    var message: String
    var age: String

    static let samples: [AppNotification] = [
        AppNotification(icon: "bag.fill.badge.plus", message: "Your order #A1042 is ready for pickup!", age: "2m ago"),
        AppNotification(icon: "sparkles", message: "New: try our Ube Matcha Latte", age: "1h ago"),
        AppNotification(icon: "gift.fill", message: "You earned a free matcha reward", age: "Yesterday")
    ]
}

enum AppearanceMode: String, Codable, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case english = "English"
    case japanese = "日本語"

    var id: String { rawValue }
}
