//
//  ProfileView.swift
//  Osacha
//
//  Customer profile screen: who they are at a glance, their loyalty card
//  right on the page, and shortcuts into the rest of the account.
//

import SwiftUI

/// The account sections reachable from the profile screen. The loyalty card
/// isn't one: it's shown on the profile itself.
private enum ProfileDestination: String, CaseIterable, Identifiable {
    case orderHistory = "Order History"
    case addresses = "Delivery Addresses"
    case payments = "Payment Methods"
    case notifications = "Notifications"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .orderHistory: return "bag.fill"
        case .addresses: return "location.fill"
        case .payments: return "creditcard.fill"
        case .notifications: return "bell.fill"
        case .settings: return "gearshape.fill"
        }
    }

    /// Each row's icon sits on its own colour from the palette, so the list
    /// reads at a glance rather than as a column of identical glyphs.
    var tint: Color {
        switch self {
        case .orderHistory: return .matchaSage
        case .addresses: return .matchaPink
        case .payments: return .matchaSageDeep
        case .notifications: return .matchaPinkPale
        case .settings: return .matchaSage.opacity(0.6)
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .orderHistory: OrderHistoryView()
        case .addresses: DeliveryAddressesView()
        case .payments: PaymentMethodsView()
        case .notifications: NotificationsView()
        case .settings: SettingsView()
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject private var controller: OrderController
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var navigator: NavigationCoordinator

    private let rows = ProfileDestination.allCases

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                banner
                memberPill

                sectionTitle("Loyalty Card")
                    .padding(.top, 8)
                LoyaltyCardView()

                sectionTitle("Account")
                    .padding(.top, 8)
                menu
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Color.matchaCream.ignoresSafeArea())
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigator.showNotifications) {
            NotificationsView()
        }
    }

    // MARK: - Banner

    /// Photo with its edit badge, the name set large, and a few numbers.
    private var banner: some View {
        HStack(alignment: .top, spacing: 18) {
            ProfileAvatar(size: 118, cornerRadius: 24)
                .overlay(alignment: .topTrailing) { editBadge }

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(firstName)
                    if !lastName.isEmpty {
                        Text(lastName)
                    }
                }
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Color.matchaDarkGreen)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

                HStack(alignment: .top, spacing: 18) {
                    stat("\(session.loyalty.stamps)/\(LoyaltyCard.stampsPerReward)", "STAMPS")
                    stat("\(session.orders.count)", "ORDERS")
                    stat("\(controller.favoriteItems.count)", "FAVORITES")
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 8)
    }

    private var firstName: String { session.profile.firstName }

    /// Everything after the first name, so "Mikaela Denise Balasoto" sets
    /// as "Mikaela" over "Denise Balasoto".
    private var lastName: String {
        session.profile.fullName
            .split(separator: " ")
            .dropFirst()
            .joined(separator: " ")
    }

    /// A pink starburst on the photo's corner that opens the profile editor.
    private var editBadge: some View {
        NavigationLink {
            EditProfileView()
        } label: {
            Image(systemName: "pencil")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.matchaDarkGreen)
                .frame(width: 40, height: 40)
                .background(Starburst(points: 12, innerRatio: 0.78).fill(Color.matchaPink))
        }
        .buttonStyle(.plain)
        .offset(x: 14, y: -14)
        .accessibilityLabel("Edit Profile")
    }

    private func stat(_ value: String, _ label: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.matchaDarkGreen)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.matchaDarkGreen.opacity(0.55))
        }
    }

    /// The member number and phone the account is under, like the strip
    /// along the bottom of a membership card.
    private var memberPill: some View {
        HStack {
            Text(memberNumber)
                .font(.system(.subheadline, design: .monospaced).weight(.semibold))
            Spacer()
            Text(session.profile.mobileNumber)
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(Color.matchaDarkGreen)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Capsule().fill(Color.matchaSageDeep))
    }

    /// The start of the member code the QR carries, grouped to read aloud
    /// at the counter: "OSA-1EG4-TE5M".
    private var memberNumber: String {
        let code = session.loyalty.memberCode.replacingOccurrences(of: "-", with: "").uppercased()
        return "OSA-\(code.prefix(4))-\(code.dropFirst(4).prefix(4))"
    }

    // MARK: - Menu

    private func sectionTitle(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .foregroundStyle(Color.matchaDarkGreen)
    }

    private var menu: some View {
        VStack(spacing: 4) {
            ForEach(rows) { row in
                NavigationLink {
                    row.destination
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: row.icon)
                            .font(.subheadline)
                            .foregroundStyle(Color.matchaDarkGreen)
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(row.tint))

                        Text(LocalizedStringKey(row.rawValue))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.matchaDarkGreen)

                        Spacer()

                        if row == .notifications, session.unreadNotificationCount > 0 {
                            Text("\(session.unreadNotificationCount)")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.matchaCardBorder))
                        }

                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.matchaDarkGreen.opacity(0.6))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.matchaSage.opacity(0.35)))
    }
}

/// A many-pointed star with shallow points, like a sticker's scalloped edge.
struct Starburst: Shape {
    var points: Int
    /// How far in the notches sit, as a fraction of the outer radius.
    var innerRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * innerRatio
        let corners = points * 2

        return Path { path in
            for index in 0..<corners {
                let angle = CGFloat(index) * .pi / CGFloat(points) - .pi / 2
                let radius = index.isMultiple(of: 2) ? outer : inner
                let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
                if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environmentObject(OrderController())
    .environmentObject(AppSession())
    .environmentObject(NavigationCoordinator())
}
