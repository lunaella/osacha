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

        /// The name to show. "Home" here is a place you live, which Japanese
        /// words differently from the Home tab, so it has its own key.
        var label: String { self == .home ? "Home (address)" : rawValue }

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

    /// The subtitle in the app's language. A card's is saved as
    /// "Expires 08/27", so its expiry is pulled back out to be reworded.
    var displaySubtitle: String {
        guard kind == .card, subtitle.hasPrefix("Expires ") else { return subtitle }
        return String(format: localized("Expires %@"), String(subtitle.dropFirst("Expires ".count)))
    }

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
    /// A pickup booked for later that the café hasn't started on yet.
    case scheduled = "Scheduled"
    case preparing = "Preparing"
    case ready = "Ready for pickup"
    case completed = "Completed"
    case outForDelivery = "Out for delivery"
    case delivered = "Delivered"

    var isFinished: Bool { self == .completed || self == .delivered }
}

/// One item line on a placed order, kept so offers can follow what the
/// customer actually orders, and so it can be ordered again as it was.
struct OrderLine: Codable, Equatable {
    var name: String
    var quantity: Int
    /// The choices made for it. Optional because lines saved before these
    /// were kept have none; reordering those uses the defaults.
    var size: DrinkSize?
    var milk: MilkOption?
    var withIceCream: Bool?

    init(name: String, quantity: Int, size: DrinkSize? = nil, milk: MilkOption? = nil, withIceCream: Bool? = nil) {
        self.name = name
        self.quantity = quantity
        self.size = size
        self.milk = milk
        self.withIceCream = withIceCream
    }

    init(_ entry: CartEntry) {
        self.init(name: entry.item.name, quantity: entry.quantity, size: entry.size,
                  milk: entry.milk, withIceCream: entry.withIceCream ? true : nil)
    }

    /// "Grande · Oat", for the receipt.
    var options: String {
        [size?.rawValue, milk?.rawValue, withIceCream == true ? "With Ice Cream" : nil]
            .compactMap { $0 }
            .map(localized)
            .joined(separator: " · ")
    }
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

    /// The pickup time the customer chose. Nil means as soon as possible.
    var scheduledFor: Date?
    /// Anything the customer asked the café to know, like "less ice".
    var note: String?
    /// Taken off the total by a free-drink reward.
    var discount: Double?
    /// Where a delivery is going, for the rider map.
    var deliveryAddress: String?

    /// The customer's rating, from 1 to 5 stars, once they've given one.
    var rating: Int?
    /// What they picked about it ("Tasty", "Fast"…) and anything they wrote.
    var ratingTags: [String]?
    var ratingComment: String?
    /// The customer said "Not now" to rating it, so it isn't asked again.
    var ratingSkipped: Bool?

    var method: Fulfillment { fulfillment ?? .pickup }

    /// A finished order with real lines can go back in the cart as it was.
    var canReorder: Bool { !(lines ?? []).isEmpty }

    /// A finished order placed in the app that hasn't been rated or skipped.
    var awaitsRating: Bool {
        placedDate != nil && status.isFinished && rating == nil && ratingSkipped != true
    }

    var summary: String {
        String(format: localized(itemCount == 1 ? "%lld item · %@" : "%lld items · %@"), itemCount, total.asPHP)
    }

    /// When it was placed, in the app's language. The seeded history has no
    /// real date behind it, so it keeps the string it was recorded with.
    var placedAtText: String {
        placedDate.map(AppDate.dayAndTime) ?? placedAt
    }

    /// Derived from how long ago the order was placed, so a drink ordered
    /// seconds ago isn't reported as already finished. Orders with no real
    /// date behind them are historical, so they read as completed.
    var status: OrderStatus {
        guard let placedDate else { return method == .delivery ? .delivered : .completed }
        let now = Date()
        let elapsed = now.timeIntervalSince(placedDate)
        switch method {
        case .pickup:
            guard let start = preparationStart, let ready = readyDate else { return .completed }
            switch now {
            case ..<start: return .scheduled
            case ..<ready: return .preparing
            case ..<ready.addingTimeInterval(Self.readyDuration - Self.preparingDuration): return .ready
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
        readyDate.map(AppDate.dayAndTime) ?? placedAt
    }

    /// When it's ready to collect, or due at the door: the chosen pickup
    /// time, or the usual wait after it was placed.
    var readyDate: Date? {
        if let scheduledFor { return scheduledFor }
        return placedDate?.addingTimeInterval(Self.leadTime(for: method))
    }

    /// When the café starts making it: straight away, or just ahead of the
    /// chosen pickup time.
    var preparationStart: Date? {
        guard let placedDate else { return nil }
        guard let scheduledFor else { return placedDate }
        return max(placedDate, scheduledFor.addingTimeInterval(-Self.preparingDuration))
    }

    /// The stages this order moves through, in order.
    var stages: [OrderStatus] {
        switch method {
        case .pickup:
            let stages: [OrderStatus] = [.preparing, .ready, .completed]
            return scheduledFor == nil ? stages : [.scheduled] + stages
        case .delivery:
            return [.preparing, .outForDelivery, .delivered]
        }
    }

    /// The total before any reward came off.
    var subtotal: Double { total + (discount ?? 0) }

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
        AppDate.dayAndTime(date.addingTimeInterval(leadTime(for: method)))
    }

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
    /// Free drinks already used at checkout.
    var rewardsRedeemed: Int = 0

    /// Free drinks earned and not yet used.
    var rewardsAvailable: Int { max(0, rewardsEarned - rewardsRedeemed) }

    /// How many more stamps this card still has room for.
    var stampsRemaining: Int { max(0, Self.stampsPerReward - stamps) }

    /// The payload encoded in the member's QR code.
    var qrPayload: String { "osacha://member/\(memberCode)" }
}

extension LoyaltyCard {
    /// Cards saved before rewards could be used have none redeemed.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        memberCode = try container.decode(String.self, forKey: .memberCode)
        stamps = try container.decode(Int.self, forKey: .stamps)
        rewardsEarned = try container.decode(Int.self, forKey: .rewardsEarned)
        rewardsRedeemed = try container.decodeIfPresent(Int.self, forKey: .rewardsRedeemed) ?? 0
    }
}

/// Something that happened on the customer's account: their order moving
/// along, a reward earned, or a welcome when they sign up.
struct AppNotification: Identifiable, Codable, Equatable {
    enum Kind: String, Codable {
        case welcome, orderPlaced, orderScheduled, orderReady, outForDelivery, delivered, reward

        var icon: String {
            switch self {
            case .welcome: return "hand.wave.fill"
            case .orderPlaced: return "bag.fill"
            case .orderScheduled: return "clock.fill"
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
            case .orderScheduled: return "Pickup booked"
            case .orderReady: return "Ready for pickup"
            case .outForDelivery: return "Out for delivery"
            case .delivered: return "Delivered"
            case .reward: return "Free matcha earned"
            }
        }

        /// The message, with `%@` standing for the notification's detail.
        var template: String {
            switch self {
            case .welcome: return "Welcome to Osacha, %@! Your loyalty card is ready — every order earns a stamp."
            case .orderPlaced: return "Order %@ placed — we're preparing it now."
            case .orderScheduled: return "Order %@ is booked — we'll have it ready at your pickup time."
            case .orderReady: return "Order %@ is ready for pickup! Show your order number at the counter."
            case .outForDelivery: return "Order %@ is out for delivery."
            case .delivered: return "Order %@ has been delivered. Enjoy your matcha!"
            case .reward: return "You earned a free matcha! Your 10th drink is on us."
            }
        }

        /// Order updates open the order history; the reward opens the card.
        var isAboutAnOrder: Bool {
            switch self {
            case .orderPlaced, .orderScheduled, .orderReady, .outForDelivery, .delivered: return true
            case .welcome, .reward: return false
            }
        }
    }

    var id = UUID()
    var kind: Kind
    var message: String
    /// What fills the message's blank: the order reference, or the
    /// customer's first name on the welcome. Kept so the message can be
    /// written again in whichever language the app is showing.
    var detail: String?
    /// When it happens. Order updates are filed at placement with the time
    /// each stage will be reached, and stay hidden until then.
    var date: Date
    var isRead = false

    /// The message in the app's language. Notifications saved before the
    /// detail was kept can only show the English they were written in.
    var text: String {
        if kind == .reward { return localized(kind.template) }
        guard let detail else { return message }
        return String(format: localized(kind.template), detail)
    }

    /// "Just now", "12m ago", "3h ago", "Yesterday", then the date.
    func age(relativeTo now: Date) -> String {
        let seconds = now.timeIntervalSince(date)
        switch seconds {
        case ..<60: return localized("Just now")
        case ..<3600: return String(format: localized("%lldm ago"), Int(seconds / 60))
        case ..<86_400: return String(format: localized("%lldh ago"), Int(seconds / 3600))
        default:
            if Calendar.current.isDateInYesterday(date) { return localized("Yesterday") }
            return AppDate.day(date)
        }
    }
}

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case english = "English"
    case japanese = "日本語"

    var id: String { rawValue }
}

/// Picks shaped by the customer's own orders: the item they order most, plus
/// something from the same menu they haven't tried yet.
struct PersonalizedOffer: Equatable {
    let item: MatchaItem
    let suggestion: MatchaItem?

    var headline: String { "Your usual" }

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
