//
//  CheckoutView.swift
//  Osacha
//
//  The last look before an order is placed: pickup or delivery, how it's
//  being paid for, and what it costs. Nothing is charged until Confirm Order.
//

import SwiftUI

struct CheckoutView: View {
    @EnvironmentObject private var controller: OrderController
    @EnvironmentObject private var session: AppSession

    @State private var fulfillment: Fulfillment = .delivery
    @State private var placedOrder: PastOrder?
    @State private var showConfirmation = false
    @State private var askForLocation = false

    private var offer: PersonalizedOffer? { session.personalizedOffer(catalog: controller.items) }
    private var offerDiscount: Double { offer?.discount(on: controller.cart) ?? 0 }
    private var total: Double { controller.cartTotal - offerDiscount }

    private var address: SavedAddress? { session.addresses.first }
    private var payment: PaymentMethod? { session.paymentMethods.first }

    /// Pickup needs no address; delivery can't go ahead without one.
    private var canConfirm: Bool {
        payment != nil && !controller.cart.isEmpty && (fulfillment == .pickup || address != nil)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    ForEach(Fulfillment.allCases) { option in
                        OptionPillView(title: option.rawValue, isSelected: fulfillment == option) {
                            withAnimation(.easeInOut(duration: 0.2)) { fulfillment = option }
                        }
                    }
                }
                .padding(.bottom, 8)

                switch fulfillment {
                case .delivery:
                    sectionTitle("Deliver to")
                    deliveryCard
                case .pickup:
                    sectionTitle("Pick up at")
                    pickupCard
                }

                sectionTitle("Pay with")
                    .padding(.top, 10)
                paymentCard

                sectionTitle("Order summary")
                    .padding(.top, 10)
                summaryCard

                Button {
                    // Delivery leans on location; ask if it's switched off.
                    if fulfillment == .delivery && !session.locationServices {
                        askForLocation = true
                    } else {
                        placeOrder()
                    }
                } label: {
                    Text("Confirm Order")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.matchaPinkDeep.opacity(canConfirm ? 1 : 0.45))
                        )
                }
                .disabled(!canConfirm)
                .padding(.top, 24)
            }
            .padding()
        }
        .background(Color.matchaSage.ignoresSafeArea())
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.matchaSageDeep, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .alert("Turn on Location Services?", isPresented: $askForLocation) {
            Button("Not Now", role: .cancel) { placeOrder() }
            Button("Turn On") {
                session.setLocationServices(true)
                placeOrder()
            }
        } message: {
            Text("Osacha uses your location to confirm your delivery address and show where your rider is.")
        }
        .navigationDestination(isPresented: $showConfirmation) {
            if let placedOrder {
                OrderConfirmationView(order: placedOrder)
                    .onAppear { controller.clearCart() }
            }
        }
    }

    private func placeOrder() {
        placedOrder = session.recordOrder(itemCount: controller.cartCount,
                                          total: total,
                                          fulfillment: fulfillment,
                                          lines: controller.cart.map { OrderLine(name: $0.item.name, quantity: $0.quantity) })
        showConfirmation = true
    }

    // MARK: - Sections

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.matchaDarkGreen)
    }

    private var deliveryCard: some View {
        detailCard(icon: address?.kind.icon ?? "house.fill",
                   title: address?.kind.rawValue ?? "No address yet",
                   lines: [address?.oneLine ?? "Add an address to deliver to.",
                           session.profile.fullName,
                           session.profile.mobileNumber]) {
            changeButton { DeliveryAddressesView() }
        }
    }

    /// There's one café, so there's nothing to change here — just who is
    /// collecting and what to show at the counter.
    private var pickupCard: some View {
        detailCard(icon: "bag.fill",
                   title: "Osacha café",
                   lines: ["Show your order number at the counter.",
                           session.profile.fullName,
                           session.profile.mobileNumber]) {
            EmptyView()
        }
    }

    private var paymentCard: some View {
        detailCard(icon: payment?.kind.icon ?? "creditcard.fill",
                   title: payment?.title ?? "No payment method",
                   lines: [payment?.subtitle ?? "Add a way to pay for this order."]) {
            changeButton { PaymentMethodsView() }
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 14) {
            summaryRow("\(controller.cartCount) item\(controller.cartCount == 1 ? "" : "s")",
                       controller.cartTotal.asPHP)
            if let offer, offerDiscount > 0 {
                summaryRow("Your offer · 15% off \(offer.item.name)", "−\(offerDiscount.asPHP)", emphasised: true)
            }
            summaryRow(fulfillment.timeLabel, PastOrder.estimatedReady(for: fulfillment), emphasised: true)

            HStack {
                Text("Total")
                    .font(.headline)
                    .foregroundStyle(Color.matchaDarkGreen)
                Spacer()
                Text(total.asPHP)
                    .font(.title3.bold())
                    .foregroundStyle(Color.matchaGreen)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.matchaCardCream))
    }

    // MARK: - Building blocks

    /// A card with an icon, a heading, supporting lines and an optional
    /// trailing control.
    private func detailCard<Trailing: View>(icon: String,
                                            title: String,
                                            lines: [String],
                                            @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.matchaGreen)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.matchaDarkGreen)
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(.caption)
                        .foregroundStyle(Color.matchaDarkGreen.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)

            trailing()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.matchaCardCream))
    }

    /// Opens the screen where that detail is managed.
    private func changeButton<Destination: View>(@ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink(destination: destination) {
            Text("Change")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.matchaGreen)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(Capsule().fill(Color.matchaSage))
        }
        .buttonStyle(.plain)
    }

    private func summaryRow(_ label: String, _ value: String, emphasised: Bool = false) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(emphasised ? .semibold : .regular)
        }
        .font(.caption)
        .foregroundStyle(Color.matchaDarkGreen)
    }
}

#Preview {
    NavigationStack {
        CheckoutView()
    }
    .environmentObject(OrderController())
    .environmentObject(AppSession())
}
