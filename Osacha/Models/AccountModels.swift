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

/// Everything saved for one mobile number. Accounts are kept per number so a
/// number the app hasn't seen before starts as a first-time customer, while
/// signing back in with a known number brings its details back.
struct AccountRecord: Codable {
    var profile: UserProfile
    var profilePhoto: Data?
    var addresses: [SavedAddress]
    var paymentMethods: [PaymentMethod]
    var orders: [PastOrder]
    var loyalty: LoyaltyCard
    var notifications: [AppNotification] = []

    /// A first-time customer: only the number is known, so the name and
    /// address are asked for straight after verification.
    static func newCustomer(mobileNumber: String) -> AccountRecord {
        AccountRecord(profile: UserProfile(fullName: "", mobileNumber: mobileNumber, address: ""),
                      profilePhoto: nil,
                      addresses: [],
                      paymentMethods: [],
                      orders: [],
                      loyalty: LoyaltyCard())
    }
}

extension AccountRecord {
    /// Accounts saved before notifications existed have none to decode.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        profile = try container.decode(UserProfile.self, forKey: .profile)
        profilePhoto = try container.decodeIfPresent(Data.self, forKey: .profilePhoto)
        addresses = try container.decode([SavedAddress].self, forKey: .addresses)
        paymentMethods = try container.decode([PaymentMethod].self, forKey: .paymentMethods)
        orders = try container.decode([PastOrder].self, forKey: .orders)
        loyalty = try container.decode(LoyaltyCard.self, forKey: .loyalty)
        notifications = try container.decodeIfPresent([AppNotification].self, forKey: .notifications) ?? []
    }
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

/// How the customer gets their order.
enum Fulfillment: String, Codable, CaseIterable, Identifiable {
    case pickup = "Pickup"
    case delivery = "Delivery"

    var id: String { rawValue }

    /// Labels the time shown on checkout and the receipt.
    var timeLabel: String {
        switch self {
        case .pickup: return "Pickup time"
        case .delivery: return "Delivery time"
        }
    }
}

enum OrderStatus: String {
    case preparing = "Preparing"
    case ready = "Ready for pickup"
    case completed = "Completed"
    case outForDelivery = "Out for delivery"
    case delivered = "Delivered"
}

/// One item line on a placed order, kept so offers can follow what the
/// customer actually orders.
struct OrderLine: Codable, Equatable {
    var name: String
    var quantity: Int
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

    /// Pickup or delivery. Optional so orders saved before customers could
    /// choose still decode — every one of those was a pickup.
    var fulfillment: Fulfillment?

    /// What was ordered. Optional because orders saved before this was
    /// recorded, and the seeded history, have no lines.
    var lines: [OrderLine]?

    var method: Fulfillment { fulfillment ?? .pickup }

    var summary: String {
        "\(itemCount) item\(itemCount == 1 ? "" : "s") · \(total.asPHP)"
    }

    /// Derived from how long ago the order was placed, so a drink ordered
    /// seconds ago isn't reported as already finished. Orders with no real
    /// date behind them are historical, so they read as completed.
    var status: OrderStatus {
        guard let placedDate else { return method == .delivery ? .delivered : .completed }
        let elapsed = Date().timeIntervalSince(placedDate)
        switch method {
        case .pickup:
            switch elapsed {
            case ..<Self.preparingDuration: return .preparing
            case ..<Self.readyDuration: return .ready
            default: return .completed
            }
        case .delivery:
            switch elapsed {
            case ..<Self.preparingDuration: return .preparing
            case ..<Self.deliveryDuration: return .outForDelivery
            default: return .delivered
            }
        }
    }

    /// When a pickup order can be collected, or a delivery should arrive.
    /// Orders with no real date behind them (the seeded history) fall back to
    /// their own recorded string, which is already a time.
    var readyAt: String {
        guard let placedDate else { return placedAt }
        return Self.timeFormatter.string(from: placedDate.addingTimeInterval(Self.leadTime(for: method)))
    }

    /// How long a new order spends in each stage before moving on.
    static let preparingDuration: TimeInterval = 5 * 60
    static let readyDuration: TimeInterval = 20 * 60
    /// Preparation plus the ride over.
    static let deliveryDuration: TimeInterval = 35 * 60

    private static func leadTime(for method: Fulfillment) -> TimeInterval {
        method == .pickup ? preparingDuration : deliveryDuration
    }

    /// The pickup or delivery time an order placed right now would get,
    /// formatted the same way the receipt shows it.
    static func estimatedReady(for method: Fulfillment, from date: Date = Date()) -> String {
        timeFormatter.string(from: date.addingTimeInterval(leadTime(for: method)))
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        // Fixed locale for the same reason the placement stamp pins one: a
        // 24-hour device would otherwise override "h:mm a".
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter
    }()

    static let samples: [PastOrder] = [
        PastOrder(reference: "A1042", placedAt: "Today, 3:15 PM", itemCount: 3, total: 870),
        PastOrder(reference: "A0998", placedAt: "Sep 4, 11:20 AM", itemCount: 2, total: 450),
        PastOrder(reference: "A0951", placedAt: "Aug 28, 4:05 PM", itemCount: 1, total: 255)
    ]
}

/// The cafe's stamp card. The printed card has ten slots: nine take a stamp,
/// and the tenth is the free matcha. Filling the ninth earns the reward, after
/// which the card starts over so the next round can be collected.
struct LoyaltyCard: Codable, Equatable {
    /// Stamps needed to earn the free tenth matcha.
    static let stampsPerReward = 9

    /// Identifies the member in the QR code the counter scans. Generated once
    /// and kept for the life of the account.
    var memberCode: String = UUID().uuidString
    var stamps: Int = 0
    var rewardsEarned: Int = 0

    /// How many more stamps this card still has room for.
    var stampsRemaining: Int { max(0, Self.stampsPerReward - stamps) }

    /// The payload encoded in the member's QR code.
    var qrPayload: String { "osacha://member/\(memberCode)" }
}

/// Something that happened on the customer's account: their order moving
/// along, a reward earned, or a welcome when they sign up.
struct AppNotification: Identifiable, Codable, Equatable {
    enum Kind: String, Codable {
        case welcome, orderPlaced, orderReady, outForDelivery, delivered, reward

        var icon: String {
            switch self {
            case .welcome: return "hand.wave.fill"
            case .orderPlaced: return "bag.fill"
            case .orderReady: return "bag.fill.badge.plus"
            case .outForDelivery: return "bicycle"
            case .delivered: return "checkmark.seal.fill"
            case .reward: return "gift.fill"
            }
        }

        /// Heading for the system banner; the message carries the detail.
        var title: String {
            switch self {
            case .welcome: return "Welcome to Osacha"
            case .orderPlaced: return "Order placed"
            case .orderReady: return "Ready for pickup"
            case .outForDelivery: return "Out for delivery"
            case .delivered: return "Delivered"
            case .reward: return "Free matcha earned"
            }
        }

        /// Order updates open the order history; the reward opens the card.
        var isAboutAnOrder: Bool {
            switch self {
            case .orderPlaced, .orderReady, .outForDelivery, .delivered: return true
            case .welcome, .reward: return false
            }
        }
    }

    var id = UUID()
    var kind: Kind
    var message: String
    /// When it happens. Order updates are filed at placement with the time
    /// each stage will be reached, and stay hidden until then.
    var date: Date
    var isRead = false

    /// "Just now", "12m ago", "3h ago", "Yesterday", then the date.
    func age(relativeTo now: Date) -> String {
        let seconds = now.timeIntervalSince(date)
        switch seconds {
        case ..<60: return "Just now"
        case ..<3600: return "\(Int(seconds / 60))m ago"
        case ..<86_400: return "\(Int(seconds / 3600))h ago"
        default:
            if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
            return Self.dayFormatter.string(from: date)
        }
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case english = "English"
    case japanese = "日本語"

    var id: String { rawValue }
}

/// A deal shaped by the customer's own orders: money off the item they order
/// most, plus something from the same menu they haven't tried yet.
struct PersonalizedOffer: Equatable {
    static let discountRate = 0.15

    let item: MatchaItem
    let suggestion: MatchaItem?

    var headline: String { "15% off your usual" }

    /// The saving on the offer item's lines in a cart.
    func discount(on cart: [CartEntry]) -> Double {
        let eligible = cart.filter { $0.item.name == item.name }.reduce(0) { $0 + $1.subtotal }
        return (eligible * Self.discountRate).rounded()
    }

    /// Nil until the customer has ordered something the catalogue still has.
    static func make(orders: [PastOrder], catalog: [MatchaItem]) -> PersonalizedOffer? {
        var counts: [String: Int] = [:]
        var firstSeen: [String: Int] = [:]
        // Orders are newest first, so ties go to the more recent favourite.
        for (index, order) in orders.enumerated() {
            for line in order.lines ?? [] {
                counts[line.name, default: 0] += line.quantity
                if firstSeen[line.name] == nil { firstSeen[line.name] = index }
            }
        }
        let ranked = counts.keys
            .filter { name in catalog.contains { $0.name == name } }
            .sorted { (counts[$0]!, -firstSeen[$0]!) > (counts[$1]!, -firstSeen[$1]!) }
        guard let top = ranked.first, let item = catalog.first(where: { $0.name == top }) else { return nil }
        let suggestion = catalog.first { $0.category == item.category && counts[$0.name] == nil }
        return PersonalizedOffer(item: item, suggestion: suggestion)
    }
}
