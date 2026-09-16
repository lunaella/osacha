//
//  ProfileView.swift
//  Osacha
//
//  Customer profile screen with account shortcuts.
//

import SwiftUI

/// The account sections reachable from the profile screen.
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

    private let rows = ProfileDestination.allCases

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ProfileAvatar(size: 100) {
                    Text("🍃").font(.system(size: 56))
                }
                .padding(.top, 12)

                VStack(spacing: 10) {
                    Text("Hello, \(session.profile.firstName)")
                        .font(.title2.bold())
                        .foregroundStyle(Color.matchaDarkGreen)

                    // A direct way in, rather than only through Settings.
                    NavigationLink {
                        EditProfileView()
                    } label: {
                        Text("Edit Profile")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.matchaGreen)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.matchaSage.opacity(0.55)))
                    }
                    .buttonStyle(.plain)
                }

                Text("\(controller.favoriteItems.count) favorites · \(controller.cartCount) in cart")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 1) {
                    ForEach(rows) { row in
                        NavigationLink {
                            row.destination
                        } label: {
                            HStack {
                                Image(systemName: row.icon)
                                    .foregroundStyle(Color.matchaGreen)
                                    .frame(width: 28)
                                Text(row.rawValue)
                                    .foregroundStyle(Color.matchaDarkGreen)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color.matchaCardCream)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.horizontal)
            }
            .padding(.bottom, 24)
        }
        .background(Color.matchaCream.ignoresSafeArea())
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environmentObject(OrderController())
    .environmentObject(AppSession())
}
