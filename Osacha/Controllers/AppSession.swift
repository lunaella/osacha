//
//  AppSession.swift
//  Osacha
//
//  Tracks whether someone is browsing as a guest or signed in, and owns the
//  account data the settings screens read and write. Guests can browse the
//  whole menu but have to sign in before an order can be placed.
//

import Foundation
import Combine
import SwiftUI
import UIKit

@MainActor
final class AppSession: ObservableObject {
    @Published private(set) var isSignedIn = false
    @Published private(set) var hasLaunched = false

    @Published var profile = UserProfile.sample
    /// The customer's profile photo, already downscaled. Nil means no photo
    /// has been chosen and the screens fall back to the leaf mark.
    @Published private(set) var profilePhoto: Data?
    @Published var addresses = SavedAddress.samples
    @Published var paymentMethods = PaymentMethod.samples
    @Published private(set) var orders = PastOrder.samples
    /// Everything filed for this account, including order updates timed for
    /// later that aren't showing yet — see `visibleNotifications`.
    @Published private(set) var notifications: [AppNotification] = []
    /// Ticks forward while the app is open so order updates filed for later
    /// appear, and the unread badge updates, when their time comes.
    @Published private(set) var now = Date()
    /// The customer's stamp card. Stamps are earned by placing orders.
    @Published private(set) var loyalty = LoyaltyCard()

    @Published var appearance: AppearanceMode = .system
    @Published var language: AppLanguage = .english

    @Published var locationServices = true
    @Published var orderTracking = true
    @Published var personalizedOffers = false
    @Published var shareAnalytics = false

    /// Number typed on the login screen, shown back on the verification screen.
    @Published var pendingNumber = ""

    private let signedInKey = "osacha.signedIn"
    private let profileKey = "osacha.profile"
    private let addressesKey = "osacha.addresses"
    private let paymentsKey = "osacha.payments"
    private let appearanceKey = "osacha.appearance"
    private let languageKey = "osacha.language"
    private let ordersKey = "osacha.orders"
    private let photoKey = "osacha.profilePhoto"
    private let loyaltyKey = "osacha.loyalty"
    private let locationKey = "osacha.locationServices"
    private let trackingKey = "osacha.orderTracking"
    private let offersKey = "osacha.personalizedOffers"
    private let analyticsKey = "osacha.shareAnalytics"
    private let accountsKey = "osacha.accounts"
    private let currentAccountKey = "osacha.currentAccount"

    /// Every account saved on this device, keyed by its ten-digit number.
    private var accounts: [String: AccountRecord] = [:]
    /// The number whose details are loaded into the properties above.
    private var currentAccount: String?

    /// A first-time customer who has verified their number but not yet told
    /// us their name and address.
    var needsProfileSetup: Bool {
        profile.fullName.trimmingCharacters(in: .whitespaces).isEmpty
            || profile.address.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var backgroundObserver: NSObjectProtocol?
    private var clock: Timer?

    init() {
        load()

        clock = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.now = Date()
            }
        }

        // Rearm the splash whenever the app leaves the foreground, so reopening
        // it always starts from the brand screen.
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.hasLaunched = false
            }
        }
    }

    deinit {
        clock?.invalidate()
        if let backgroundObserver {
            NotificationCenter.default.removeObserver(backgroundObserver)
        }
    }

    // MARK: - Launch

    func finishLaunching() {
        hasLaunched = true
    }

    /// Called when the app goes to the background so the splash plays again
    /// the next time it is opened, not just on a cold start.
    func resetLaunch() {
        hasLaunched = false
    }

    // MARK: - Authentication

    /// The prototype accepts any six digits. Verifying loads the account for
    /// the number typed on the login screen — or starts a new one if this
    /// number hasn't been seen — and returns true when it's a first-time
    /// customer who still needs to give their name and address. They stay
    /// signed out until they have.
    @discardableResult
    func verifyCode() -> Bool {
        let number = Self.accountKey(for: pendingNumber)
        if !number.isEmpty {
            switchToAccount(number)
        }
        guard !needsProfileSetup else {
            persist()
            return true
        }
        isSignedIn = true
        persist()
        return false
    }

    /// Finishes a first-time customer's sign-up with the details asked for
    /// after verification, then signs them in.
    func completeProfile(fullName: String, address: SavedAddress) {
        profile.fullName = fullName.trimmingCharacters(in: .whitespaces)
        profile.address = address.oneLine
        addresses.insert(address, at: 0)
        notify(.welcome, "Welcome to Osacha, \(profile.firstName)! Your loyalty card is ready — every order earns a stamp.")
        isSignedIn = true
        persist()
    }

    /// Loads the saved details for a number into the session, creating a
    /// blank account the first time a number signs in.
    private func switchToAccount(_ number: String) {
        guard number != currentAccount else { return }
        let record = accounts[number]
            ?? .newCustomer(mobileNumber: Self.formattedMobileNumber(number))
        apply(record)
        currentAccount = number
    }

    private func apply(_ record: AccountRecord) {
        profile = record.profile
        profilePhoto = record.profilePhoto
        addresses = record.addresses
        paymentMethods = record.paymentMethods
        orders = record.orders
        loyalty = record.loyalty
        notifications = record.notifications
        now = Date()
    }

    private var currentRecord: AccountRecord {
        AccountRecord(profile: profile, profilePhoto: profilePhoto, addresses: addresses,
                      paymentMethods: paymentMethods, orders: orders, loyalty: loyalty,
                      notifications: notifications)
    }

    /// The last ten digits of a number, so "+63 917 123 4567" and "9171234567"
    /// refer to the same account.
    private static func accountKey(for raw: String) -> String {
        String(raw.filter(\.isNumber).suffix(10))
    }

    /// Groups a typed number as "+63 917 123 4567" so it matches the spacing
    /// the profile screens already display.
    static func formattedMobileNumber(_ raw: String) -> String {
        let digits = raw.filter(\.isNumber)
        guard digits.count == 10 else { return "+63 " + digits }
        let area = digits.prefix(3)
        let middle = digits.dropFirst(3).prefix(3)
        let last = digits.dropFirst(6)
        return "+63 \(area) \(middle) \(last)"
    }

    // MARK: - Profile photo

    /// Stores a newly chosen photo, or clears it when passed nil. The image is
    /// squared off and shrunk first — a full-resolution shot from the library
    /// is far larger than a 100pt avatar needs, and this is written to
    /// UserDefaults alongside the rest of the profile.
    func updateProfilePhoto(_ image: UIImage?) {
        guard let image else {
            profilePhoto = nil
            persist()
            return
        }
        profilePhoto = Self.squareThumbnail(image, side: 512)
        persist()
    }

    private static func squareThumbnail(_ image: UIImage, side: CGFloat) -> Data? {
        let shortest = min(image.size.width, image.size.height)
        let crop = CGRect(x: (image.size.width - shortest) / 2,
                          y: (image.size.height - shortest) / 2,
                          width: shortest, height: shortest)
        let squared: UIImage
        if let cg = image.cgImage?.cropping(to: crop) {
            squared = UIImage(cgImage: cg, scale: image.scale, orientation: image.imageOrientation)
        } else {
            squared = image
        }
        let target = CGSize(width: side, height: side)
        // Scale 1, or the renderer uses the screen's (3x on this device) and
        // writes a 1536px image — several hundred KB of UserDefaults for a
        // 100pt avatar.
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        let resized = renderer.image { _ in
            squared.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: 0.85)
    }

    func continueAsGuest() {
        isSignedIn = false
        persist()
    }

    func signOut() {
        isSignedIn = false
        pendingNumber = ""
        persist()
    }

    // MARK: - Addresses

    func addAddress(_ address: SavedAddress) {
        addresses.append(address)
        persist()
    }

    func update(_ address: SavedAddress) {
        guard let index = addresses.firstIndex(where: { $0.id == address.id }) else { return }
        addresses[index] = address
        persist()
    }

    func removeAddress(_ address: SavedAddress) {
        addresses.removeAll { $0.id == address.id }
        persist()
    }

    // MARK: - Payment methods

    func addPaymentMethod(_ method: PaymentMethod) {
        paymentMethods.append(method)
        persist()
    }

    func removePaymentMethod(_ method: PaymentMethod) {
        paymentMethods.removeAll { $0.id == method.id }
        persist()
    }

    // MARK: - Orders

    /// Files a placed order into the history and returns it for the receipt screen.
    @discardableResult
    func recordOrder(itemCount: Int, total: Double, fulfillment: Fulfillment, lines: [OrderLine]) -> PastOrder {
        let reference = String(format: "A%04d", Int.random(in: 1000...9999))
        let now = Date()
        let order = PastOrder(reference: reference,
                              placedAt: Self.timestampFormatter.string(from: now),
                              itemCount: itemCount,
                              total: total,
                              placedDate: now,
                              fulfillment: fulfillment,
                              lines: lines)
        orders.insert(order, at: 0)

        // File every update this order will get, each at the time it happens.
        // Catch the clock up first so the "placed" update shows immediately.
        self.now = now
        let ref = "#\(order.reference)"
        var updates = [AppNotification(kind: .orderPlaced,
                                       message: "Order \(ref) placed — we're preparing it now.",
                                       date: now)]
        let ready = now.addingTimeInterval(PastOrder.preparingDuration)
        switch fulfillment {
        case .pickup:
            updates.append(AppNotification(kind: .orderReady,
                                           message: "Order \(ref) is ready for pickup! Show your order number at the counter.",
                                           date: ready))
        case .delivery:
            updates.append(AppNotification(kind: .outForDelivery,
                                           message: "Order \(ref) is out for delivery.",
                                           date: ready))
            updates.append(AppNotification(kind: .delivered,
                                           message: "Order \(ref) has been delivered. Enjoy your matcha!",
                                           date: now.addingTimeInterval(PastOrder.deliveryDuration)))
        }
        if awardLoyaltyStamp() {
            updates.append(AppNotification(kind: .reward,
                                           message: "You earned a free matcha! Your 10th drink is on us.",
                                           date: now))
        }
        notifications.append(contentsOf: updates)

        // The phone itself only announces what happens later, and only if the
        // customer hasn't turned order tracking off.
        if orderTracking {
            NotificationScheduler.shared.schedule(updates.filter { $0.date > now })
        }
        persist()
        return order
    }

    // MARK: - Privacy

    /// Turning location on also asks iOS for permission the first time.
    func setLocationServices(_ on: Bool) {
        locationServices = on
        if on { LocationAuthorizer.shared.requestPermission() }
        persist()
    }

    /// The customer's current offer, when they've opted in and have ordered
    /// something to base it on.
    func personalizedOffer(catalog: [MatchaItem]) -> PersonalizedOffer? {
        guard isSignedIn, personalizedOffers else { return nil }
        return PersonalizedOffer.make(orders: orders, catalog: catalog)
    }

    // MARK: - Notifications

    /// Notifications whose time has come, newest first.
    var visibleNotifications: [AppNotification] {
        notifications.filter { $0.date <= now }.sorted { $0.date > $1.date }
    }

    var unreadNotificationCount: Int {
        visibleNotifications.filter { !$0.isRead }.count
    }

    /// Marks everything currently showing as read. Updates still waiting for
    /// their time stay unread so they count once they appear.
    func markNotificationsRead() {
        var changed = false
        for index in notifications.indices where notifications[index].date <= now && !notifications[index].isRead {
            notifications[index].isRead = true
            changed = true
        }
        if changed { persist() }
    }

    private func notify(_ kind: AppNotification.Kind, _ message: String) {
        now = Date()
        notifications.append(AppNotification(kind: kind, message: message, date: now))
    }

    // MARK: - Loyalty

    /// Adds a stamp to the card, completing it and starting a fresh one on the
    /// tenth. Returns true when this stamp completed a card.
    @discardableResult
    func awardLoyaltyStamp() -> Bool {
        loyalty.stamps += 1
        let completed = loyalty.stamps >= LoyaltyCard.stampsPerReward
        if completed {
            loyalty.rewardsEarned += 1
            loyalty.stamps = 0
        }
        persist()
        return completed
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        // Without a fixed locale the device's 12/24-hour setting overrides the
        // "h:mm a" pattern, so the same app shows "3:15 PM" on one phone and
        // "15:15" on another.
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter
    }()

    // MARK: - Persistence

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(isSignedIn, forKey: signedInKey)
        defaults.set(appearance.rawValue, forKey: appearanceKey)
        defaults.set(language.rawValue, forKey: languageKey)
        defaults.set(locationServices, forKey: locationKey)
        defaults.set(orderTracking, forKey: trackingKey)
        defaults.set(personalizedOffers, forKey: offersKey)
        defaults.set(shareAnalytics, forKey: analyticsKey)
        // Only a verified number has an account to write to; a guest's
        // placeholder details are never saved.
        if let currentAccount {
            accounts[currentAccount] = currentRecord
            defaults.set(currentAccount, forKey: currentAccountKey)
        }
        if let data = try? JSONEncoder().encode(accounts) { defaults.set(data, forKey: accountsKey) }
    }

    private func load() {
        let defaults = UserDefaults.standard
        isSignedIn = defaults.bool(forKey: signedInKey)
        if let raw = defaults.string(forKey: appearanceKey), let mode = AppearanceMode(rawValue: raw) {
            appearance = mode
        }
        if let raw = defaults.string(forKey: languageKey), let value = AppLanguage(rawValue: raw) {
            language = value
        }
        // Privacy choices; anything never set keeps its default.
        if defaults.object(forKey: locationKey) != nil { locationServices = defaults.bool(forKey: locationKey) }
        if defaults.object(forKey: trackingKey) != nil { orderTracking = defaults.bool(forKey: trackingKey) }
        if defaults.object(forKey: offersKey) != nil { personalizedOffers = defaults.bool(forKey: offersKey) }
        if defaults.object(forKey: analyticsKey) != nil { shareAnalytics = defaults.bool(forKey: analyticsKey) }
        if let data = defaults.data(forKey: accountsKey),
           let decoded = try? JSONDecoder().decode([String: AccountRecord].self, from: data) {
            accounts = decoded
            currentAccount = defaults.string(forKey: currentAccountKey)
        } else if let legacy = legacyAccount(from: defaults) {
            // Installs from before accounts were kept per number saved a
            // single set of details; file them under that profile's number.
            let number = Self.accountKey(for: legacy.profile.mobileNumber)
            accounts[number] = legacy
            currentAccount = number
            // Load the old details before saving: persist() writes whatever
            // the session currently holds, which until now is placeholder data.
            apply(legacy)
            persist()
            [profileKey, addressesKey, paymentsKey, ordersKey, loyaltyKey, photoKey]
                .forEach(defaults.removeObject(forKey:))
            return
        }
        if let currentAccount, let record = accounts[currentAccount] {
            apply(record)
        }
    }

    /// The single account saved by earlier versions, if there is one.
    private func legacyAccount(from defaults: UserDefaults) -> AccountRecord? {
        let decoder = JSONDecoder()
        guard let data = defaults.data(forKey: profileKey),
              let profile = try? decoder.decode(UserProfile.self, from: data) else { return nil }
        func decode<T: Decodable>(_ key: String, _ fallback: T) -> T {
            defaults.data(forKey: key).flatMap { try? decoder.decode(T.self, from: $0) } ?? fallback
        }
        return AccountRecord(profile: profile,
                             profilePhoto: defaults.data(forKey: photoKey),
                             addresses: decode(addressesKey, SavedAddress.samples),
                             paymentMethods: decode(paymentsKey, PaymentMethod.samples),
                             orders: decode(ordersKey, PastOrder.samples),
                             loyalty: decode(loyaltyKey, LoyaltyCard()))
    }

    /// Persist preference changes made directly through the bindings.
    func savePreferences() {
        persist()
    }
}

/// Owns the Home tab's navigation stack so a screen deep in the ordering flow
/// — the receipt, in particular — can return all the way to the menu root
/// rather than popping one level back into the cart it just emptied.
@MainActor
final class NavigationCoordinator: ObservableObject {
    @Published var homePath = NavigationPath()
    /// Which tab is showing, so the brand mark can return to Home from any of
    /// them rather than only unwinding the Home stack.
    @Published var selectedTab: AppTab = .home

    /// Pushes the Notifications screen on the Profile tab when a banner is tapped.
    @Published var showNotifications = false

    func returnHome() {
        selectedTab = .home
        homePath = NavigationPath()
    }

    func openNotifications() {
        selectedTab = .profile
        showNotifications = true
    }
}

enum AppTab: Hashable {
    case home, search, favorites, profile
}
