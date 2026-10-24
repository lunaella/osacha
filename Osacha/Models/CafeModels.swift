//
//  CafeModels.swift
//  Osacha
//
//  Facts about the café itself: when it's open, which pickup times it can
//  offer, where it is, and what goes into each item on the menu.
//

import Foundation
import CoreLocation

/// The café's opening hours, the same every day.
enum Cafe {
    static let opensAt = 9
    static let closesAt = 20

    /// Placeholder location until the café has a real one: Maginhawa Street,
    /// Quezon City.
    static let coordinate = CLLocationCoordinate2D(latitude: 14.6467, longitude: 121.0587)
    static let address = "Maginhawa Street, Quezon City"

    /// Pickup times are offered on the quarter hour.
    static let slotLength: TimeInterval = 15 * 60

    private static var calendar: Calendar { Calendar.current }

    static func opening(on day: Date) -> Date {
        calendar.date(bySettingHour: opensAt, minute: 0, second: 0, of: day) ?? day
    }

    static func closing(on day: Date) -> Date {
        calendar.date(bySettingHour: closesAt, minute: 0, second: 0, of: day) ?? day
    }

    static func isOpen(at date: Date = Date()) -> Bool {
        date >= opening(on: date) && date < closing(on: date)
    }

    /// Whether an order placed now could still be made before closing.
    static func takesOrdersNow(at date: Date = Date()) -> Bool {
        isOpen(at: date) && date.addingTimeInterval(PastOrder.preparingDuration) < closing(on: date)
    }

    /// The next time the doors open: later today, or tomorrow morning.
    static func nextOpening(after date: Date = Date()) -> Date {
        let today = opening(on: date)
        if date < today { return today }
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        return opening(on: tomorrow)
    }

    /// "Open now · until 8:00 PM", "Closed · opens 9:00 AM" or, after
    /// closing, "Closed · opens tomorrow 9:00 AM".
    static func statusText(at date: Date = Date()) -> String {
        if isOpen(at: date) {
            return String(format: localized("Open now · until %@"), AppDate.time(closing(on: date)))
        }
        let next = nextOpening(after: date)
        let key = calendar.isDate(next, inSameDayAs: date) ? "Closed · opens %@" : "Closed · opens tomorrow %@"
        return String(format: localized(key), AppDate.time(next))
    }

    /// "9:00 AM – 8:00 PM", for the pickup card.
    static var hoursText: String {
        let now = Date()
        return "\(AppDate.time(opening(on: now))) – \(AppDate.time(closing(on: now)))"
    }

    /// The pickup times a customer can choose from: every quarter hour from
    /// the first one there's time to make the order for, until closing. When
    /// today has none left, the next day's times are offered instead.
    static func pickupSlots(from date: Date = Date()) -> [Date] {
        var earliest = date.addingTimeInterval(slotLength)
        if !isOpen(at: earliest) || earliest >= closing(on: earliest) {
            earliest = nextOpening(after: date).addingTimeInterval(slotLength)
        }
        var slot = roundUp(earliest)
        let close = closing(on: slot)
        var slots: [Date] = []
        while slot < close {
            slots.append(slot)
            slot = slot.addingTimeInterval(slotLength)
        }
        return slots
    }

    private static func roundUp(_ date: Date) -> Date {
        let seconds = date.timeIntervalSinceReferenceDate
        return Date(timeIntervalSinceReferenceDate: (seconds / slotLength).rounded(.up) * slotLength)
    }
}

/// The rider bringing a delivery. Not a real person yet, like the support
/// agent: the details are fixed so the tracking screen has someone to show.
enum Rider {
    static let name = "Paolo R."
    static let vehicle = "Honda Click · NBC 4821"
    static let phone = "+63 917 555 0123"
}

/// Ingredients people most often need to avoid.
enum Allergen: String, CaseIterable, Identifiable {
    case dairy = "Dairy"
    case egg = "Egg"
    case gluten = "Gluten"
    case nuts = "Tree nuts"
    case soy = "Soy"

    var id: String { rawValue }
}

extension MilkOption {
    /// What choosing this milk adds to a drink. Oat adds nothing on the list.
    var allergen: Allergen? {
        switch self {
        case .regular: return .dairy
        case .soy: return .soy
        case .almond: return .nuts
        case .oat: return nil
        }
    }
}

extension MatchaItem {
    /// What's in each item apart from a choosable milk, by name, and whether
    /// it has caffeine. Matcha, hojicha and espresso all do.
    private static let ingredients: [String: (allergens: Set<Allergen>, caffeine: Bool)] = [
        "Usucha": ([], true),
        "Matcha Latte": ([], true),
        "Strawberry Matcha Latte": ([], true),
        "Rose Matcha Latte": ([.dairy], true),
        "Ube Matcha Latte": ([], true),
        "Einspanner Matcha Latte": ([.dairy], true),
        "Matcha Cloud Tiramisu Latte": ([.dairy, .egg], true),
        "Banana Matcha": ([], true),
        "Egg Matcha": ([.dairy, .egg], true),
        "London Fog Matcha": ([.dairy], true),
        "Iced Matcha Coco": ([], true),
        "Coconut Matcha Cloud": ([.dairy], true),
        "Cheese Cloud Matcha": ([.dairy], true),
        "Banana Pudding Matcha": ([.dairy, .egg, .gluten], true),

        "Matcha Tiramisu": ([.dairy, .egg, .gluten], true),
        "Matcha Brownie": ([.dairy, .egg, .gluten], true),
        "Matcha Caramel Pudding": ([.dairy, .egg], true),
        "Matcha Basque Cheesecake": ([.dairy, .egg, .gluten], true),
        "Matcha Mille Crepe Cake": ([.dairy, .egg, .gluten], true),
        "Matcha Strawberry Daifuku Souffle Pancake": ([.dairy, .egg, .gluten], true),
        "Matcha Fresh Cream Swiss Roll": ([.dairy, .egg, .gluten], true),

        "Matcha Sakura Cake": ([.dairy, .egg, .gluten], true),
        "Matcha Sakura Crepe": ([.dairy, .egg, .gluten], true),
        "Sakura Bingsu": ([.dairy, .egg, .gluten], false),
        "Matcha Sakura Latte": ([.dairy], true),
        "Sakura Americano": ([], true),

        "Cookie Butter Latte": ([.dairy, .gluten, .soy], true),
        "Pistachio Cream Latte": ([.dairy, .nuts], true),
        "Ube Hojicha Latte": ([.dairy], true),
        "Vanilla Sea Salt Latte": ([.dairy], true),
        "Strawberry Hojicha Latte": ([.dairy], true)
    ]

    /// The allergens in this item as ordered. A drink with a milk choice
    /// takes on whatever that milk brings, so oat milk can make it dairy-free.
    func allergens(milk: MilkOption?, withIceCream: Bool = false) -> [Allergen] {
        var found = Self.ingredients[name]?.allergens ?? []
        if hasMilkOptions, let extra = (milk ?? .regular).allergen {
            found.insert(extra)
        }
        if withIceCream { found.insert(.dairy) }
        return Allergen.allCases.filter(found.contains)
    }

    var hasCaffeine: Bool { Self.ingredients[name]?.caffeine ?? true }
}
