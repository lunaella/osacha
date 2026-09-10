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

                        Text("Completed")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.matchaGreen)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.matchaSage.opacity(0.45)))
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

struct NotificationsView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(session.notifications) { note in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: note.icon)
                            .foregroundStyle(Color.matchaGreen)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 5) {
                            Text(note.message)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.matchaDarkGreen)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(note.age)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(16)
                    .accountCard()
                }
            }
            .padding()
        }
        .accountBackground()
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { OrderHistoryView() }
        .environmentObject(AppSession())
}
