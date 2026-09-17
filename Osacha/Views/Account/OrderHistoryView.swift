//
//  OrderHistoryView.swift
//  Osacha
//
//  Past orders, newest first.
//

import SwiftUI

struct OrderHistoryView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(session.orders) { order in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Order #\(order.reference)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.matchaDarkGreen)
                            Text(order.placedAt)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(order.summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(order.status.rawValue)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(order.status.foreground)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(order.status.background))
                    }
                    .padding(16)
                    .accountCard()
                }
            }
            .padding()
        }
        .accountBackground()
        .navigationTitle("Order History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension OrderStatus {
    var foreground: Color {
        switch self {
        case .preparing: return Color.matchaPinkDeep
        case .ready, .outForDelivery: return Color.matchaDarkGreen
        case .completed, .delivered: return Color.matchaGreen
        }
    }

    var background: Color {
        switch self {
        case .preparing: return Color.matchaPinkPale
        case .ready, .outForDelivery: return Color.matchaSage
        case .completed, .delivered: return Color.matchaSage.opacity(0.45)
        }
    }
}

struct NotificationsView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if session.visibleNotifications.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "bell.slash")
                            .font(.title2)
                            .foregroundStyle(Color.matchaGreen)
                        Text("You're all caught up")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.matchaDarkGreen)
                        Text("Order updates and rewards will show up here.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .accountCard()
                } else {
                    ForEach(session.visibleNotifications) { note in
                        NavigationLink {
                            destination(for: note)
                        } label: {
                            row(note)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .accountBackground()
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        // Leave the unread dots up while the list is on screen, so the
        // customer can see what's new, then clear them on the way out.
        .onDisappear { session.markNotificationsRead() }
    }

    private func row(_ note: AppNotification) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: note.kind.icon)
                .foregroundStyle(Color.matchaGreen)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 5) {
                Text(note.message)
                    .font(.caption.weight(note.isRead ? .regular : .semibold))
                    .foregroundStyle(Color.matchaDarkGreen)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(note.age(relativeTo: session.now))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            if !note.isRead {
                Circle()
                    .fill(Color.matchaPinkDeep)
                    .frame(width: 8, height: 8)
                    .padding(.top, 4)
                    .accessibilityLabel("Unread")
            }
        }
        .padding(16)
        .contentShape(Rectangle())
        .accountCard()
    }

    @ViewBuilder
    private func destination(for note: AppNotification) -> some View {
        if note.kind.isAboutAnOrder {
            OrderHistoryView()
        } else {
            LoyaltyCardView()
        }
    }
}

#Preview {
    NavigationStack { OrderHistoryView() }
        .environmentObject(AppSession())
}
