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

    @State private var showTracking = false
    @State private var askForLocation = false

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
                        Text(order.method.timeLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(order.readyAt)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.matchaDarkGreen)
                    }
                }
                .padding(20)
                .accountCard()
                .padding(.top, 8)

                // The order just earned a stamp, so say so here rather than
                // leaving the customer to find it on the card.
                NavigationLink {
                    LoyaltyCardView()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                        Text("+1 stamp added to your loyalty card")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(Color.matchaGreen)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.matchaSage.opacity(0.55)))
                    .padding(.horizontal)
                }
                .buttonStyle(.plain)

                Button {
                    // Following a rider needs location; pickups don't.
                    if order.method == .delivery && !session.locationServices {
                        askForLocation = true
                    } else {
                        showTracking = true
                    }
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
        .navigationDestination(isPresented: $showTracking) {
            OrderHistoryView()
        }
        .alert("Turn on Location Services?", isPresented: $askForLocation) {
            Button("Not Now", role: .cancel) { showTracking = true }
            Button("Turn On") {
                session.setLocationServices(true)
                showTracking = true
            }
        } message: {
            Text("Osacha uses your location to show where your rider is on the way.")
        }
    }
}

#Preview {
    NavigationStack {
        OrderConfirmationView(order: PastOrder.samples[0])
    }
    .environmentObject(AppSession())
    .environmentObject(NavigationCoordinator())
}
