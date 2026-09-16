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
    @Published var notifications = AppNotification.samples

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

    private var backgroundObserver: NSObjectProtocol?

    init() {
        load()

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

    /// The prototype accepts any six digits; this just flips the session state.
    func verifyCode() {
        isSignedIn = true
        if !pendingNumber.isEmpty {
            profile.mobileNumber = Self.formattedMobileNumber(pendingNumber)
        }
        persist()
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
    func recordOrder(itemCount: Int, total: Double) -> PastOrder {
        let reference = String(format: "A%04d", Int.random(in: 1000...9999))
        let now = Date()
        let order = PastOrder(reference: reference,
                              placedAt: Self.timestampFormatter.string(from: now),
                              itemCount: itemCount,
                              total: total,
                              placedDate: now)
        orders.insert(order, at: 0)
        persist()
        return order
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
        if let data = try? JSONEncoder().encode(profile) { defaults.set(data, forKey: profileKey) }
        if let data = try? JSONEncoder().encode(addresses) { defaults.set(data, forKey: addressesKey) }
        if let data = try? JSONEncoder().encode(paymentMethods) { defaults.set(data, forKey: paymentsKey) }
        if let data = try? JSONEncoder().encode(orders) { defaults.set(data, forKey: ordersKey) }
        if let profilePhoto { defaults.set(profilePhoto, forKey: photoKey) }
        else { defaults.removeObject(forKey: photoKey) }
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
        if let data = defaults.data(forKey: profileKey),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            profile = decoded
        }
        if let data = defaults.data(forKey: addressesKey),
           let decoded = try? JSONDecoder().decode([SavedAddress].self, from: data) {
            addresses = decoded
        }
        if let data = defaults.data(forKey: paymentsKey),
           let decoded = try? JSONDecoder().decode([PaymentMethod].self, from: data) {
            paymentMethods = decoded
        }
        profilePhoto = defaults.data(forKey: photoKey)
        if let data = defaults.data(forKey: ordersKey),
           let decoded = try? JSONDecoder().decode([PastOrder].self, from: data) {
            orders = decoded
        }
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

    func returnHome() {
        selectedTab = .home
        homePath = NavigationPath()
    }
}

enum AppTab: Hashable {
    case home, search, favorites, profile
}
