//
//  OrderConfirmationView.swift
//  Osacha
//
//  Receipt shown after an order is placed, replacing the old alert.
//

import SwiftUI

struct OrderConfirmationView: View {
    let order: PastOrder

    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var navigator: NavigationCoordinator

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 120, height: 120)
                    .background(Circle().fill(Color.matchaGreen))
                    .shadow(color: Color.matchaGreen.opacity(0.3), radius: 18, y: 8)
                    .padding(.top, 40)

                Text("Order Placed!")
                    .font(.title.bold())
                    .foregroundStyle(Color.matchaDarkGreen)

                Text("Thanks for your order — your matcha will be ready shortly.")
                    .font(.subheadline)
                    .foregroundStyle(Color.matchaDarkGreen.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                VStack(spacing: 14) {
                    Text("Order #\(order.reference)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.matchaDarkGreen)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        Text("Total Paid")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(order.total.asPHP)
                            .font(.title3.bold())
                            .foregroundStyle(Color.matchaGreen)
                    }

                    HStack {
                        Text("Pickup time")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(order.pickupAt)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.matchaDarkGreen)
                    }
                }
                .padding(20)
                .accountCard()
                .padding(.top, 8)

                NavigationLink {
                    OrderHistoryView()
                } label: {
                    PrimaryButtonLabel(title: "Track Order")
                }
                .padding(.top, 8)

                Button {
                    navigator.returnHome()
                } label: {
                    Text("Back to Home")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.matchaGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.matchaGreen, lineWidth: 1.5)
                        )
                }
            }
            .padding()
        }
        .accountBackground()
        .navigationBarBackButtonHidden(true)
        // The receipt is a full-screen moment in the design, with no tab bar.
        .toolbar(.hidden, for: .tabBar)
    }
}

#Preview {
    NavigationStack {
        OrderConfirmationView(order: PastOrder.samples[0])
    }
    .environmentObject(AppSession())
    .environmentObject(NavigationCoordinator())
}
