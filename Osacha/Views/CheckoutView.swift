//
//  CheckoutView.swift
//  Osacha
//
//  The last look before an order is placed: pickup or delivery and when,
//  a note for the café, how it's being paid for, any free drink to use, and
//  what it costs. Nothing is charged until Confirm Order.
//

import SwiftUI

struct CheckoutView: View {
    @EnvironmentObject private var controller: OrderController
    @EnvironmentObject private var session: AppSession

    @State private var fulfillment: Fulfillment = .delivery
    @State private var placedOrder: PastOrder?
    @State private var showConfirmation = false
    @State private var askForLocation = false
    /// The chosen pickup time; nil is as soon as possible.
    @State private var pickupTime: Date?
    @State private var note = ""
    @State private var useReward = false

    /// The café can start on an order right now.
    private var openNow: Bool { Cafe.takesOrdersNow(at: session.now) }
    private var slots: [Date] { Cafe.pickupSlots(from: session.now) }

    /// What a free-drink reward takes off, when one is being used.
    private var discount: Double {
        guard useReward, session.loyalty.rewardsAvailable > 0 else { return 0 }
        return controller.rewardDrinkPrice ?? 0
    }

    private var total: Double { controller.cartTotal - discount }

    private var address: SavedAddress? { session.addresses.first }
    private var payment: PaymentMethod? { session.paymentMethods.first }

    /// Pickup needs no address; delivery can't go ahead without one. Outside
    /// opening hours only a pickup booked for later can be placed.
    private var canConfirm: Bool {
        guard payment != nil, !controller.cart.isEmpty else { return false }
        switch fulfillment {
        case .pickup: return openNow || pickupTime != nil
        case .delivery: return openNow && address != nil
        }
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
                    if !openNow {
                        closedNote("Delivery is back when we open. Choose Pickup to order ahead.")
                    }
                case .pickup:
                    sectionTitle("Pick up at")
                    pickupCard
                    sectionTitle("Pickup time")
                        .padding(.top, 10)
                    pickupTimeSection
                }

                sectionTitle("Note for the café")
                    .padding(.top, 10)
                noteField

                if session.loyalty.rewardsAvailable > 0 {
                    sectionTitle("Rewards")
                        .padding(.top, 10)
                    rewardCard
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
        .onAppear {
            // Closed for the day: the only order that can go ahead is a
            // pickup for when the café opens again.
            if !openNow {
                fulfillment = .pickup
                pickupTime = pickupTime ?? slots.first
            }
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
                                          lines: controller.cart.map(OrderLine.init),
                                          scheduledFor: fulfillment == .pickup ? pickupTime : nil,
                                          note: note,
                                          rewardDiscount: discount,
                                          deliveryAddress: address?.oneLine)
        showConfirmation = true
    }

    // MARK: - Sections

    private func sectionTitle(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.matchaDarkGreen)
    }

    private var deliveryCard: some View {
        detailCard(icon: address?.kind.icon ?? "house.fill",
                   title: address?.kind.label ?? "No address yet",
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
                           String(format: localized("Open daily %@"), Cafe.hoursText),
                           session.profile.fullName,
                           session.profile.mobileNumber]) {
            EmptyView()
        }
    }

    private var paymentCard: some View {
        detailCard(icon: payment?.kind.icon ?? "creditcard.fill",
                   title: payment?.title ?? "No payment method",
                   lines: [payment?.displaySubtitle ?? "Add a way to pay for this order."]) {
            changeButton { PaymentMethodsView() }
        }
    }

    /// As soon as possible, or a quarter-hour slot from now until closing.
    private var pickupTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                OptionPillView(title: "As soon as possible",
                               detail: openNow ? PastOrder.estimatedReady(for: .pickup) : nil,
                               isSelected: pickupTime == nil) {
                    withAnimation(.easeInOut(duration: 0.2)) { pickupTime = nil }
                }
                .disabled(!openNow)
                .opacity(openNow ? 1 : 0.45)

                OptionPillView(title: "Schedule",
                               detail: pickupTime.map(AppDate.time),
                               isSelected: pickupTime != nil) {
                    withAnimation(.easeInOut(duration: 0.2)) { pickupTime = pickupTime ?? slots.first }
                }
            }

            if let chosen = pickupTime {
                if let first = slots.first, !Calendar.current.isDateInToday(first) {
                    Text("Tomorrow")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.matchaDarkGreen.opacity(0.75))
                }
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(slots, id: \.self) { slot in
                                slotChip(slot, isSelected: slot == chosen)
                                    .id(slot)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .onAppear { proxy.scrollTo(chosen, anchor: .center) }
                }
            }

            if !openNow {
                closedNote("We're closed right now — book a time and we'll have it ready.")
            }
        }
    }

    private func slotChip(_ slot: Date, isSelected: Bool) -> some View {
        Button {
            pickupTime = slot
        } label: {
            Text(AppDate.time(slot))
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .white : Color.matchaDarkGreen)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Capsule().fill(isSelected ? Color.matchaGreen : Color.white))
        }
        .buttonStyle(.plain)
    }

    /// The café's hours, said where they stop the customer doing something.
    private func closedNote(_ text: LocalizedStringKey) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(Cafe.statusText(at: session.now))
                    .fontWeight(.semibold)
                Text(text)
            }
        } icon: {
            Image(systemName: "clock")
        }
        .font(.caption)
        .foregroundStyle(Color.matchaPinkDeep)
    }

    private var noteField: some View {
        TextField("Less ice, no straw, call when outside…", text: $note, axis: .vertical)
            .lineLimit(2...4)
            .font(.subheadline)
            .foregroundStyle(Color.matchaDarkGreen)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.matchaCardCream))
    }

    /// Turns a completed stamp card into a free drink on this order.
    @ViewBuilder
    private var rewardCard: some View {
        if let price = controller.rewardDrinkPrice {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { useReward.toggle() }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: useReward ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(useReward ? Color.matchaGreen : Color.matchaDarkGreen.opacity(0.4))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Use my free drink")
                            .font(.subheadline.weight(.semibold))
                        Text("Your priciest drink, \(price.asPHP), is on us.")
                            .font(.caption)
                            .foregroundStyle(Color.matchaDarkGreen.opacity(0.75))
                    }
                    Spacer()
                    Image(systemName: "gift.fill")
                        .foregroundStyle(Color.matchaPinkDeep)
                }
                .foregroundStyle(Color.matchaDarkGreen)
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(useReward ? Color.matchaPinkPale : Color.matchaCardCream))
            }
            .buttonStyle(.plain)
        } else {
            Label("You have a free drink — add one to your cart to use it.", systemImage: "gift.fill")
                .font(.caption)
                .foregroundStyle(Color.matchaDarkGreen)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.matchaCardCream))
        }
    }

    private var readyText: String {
        if fulfillment == .pickup, let pickupTime { return AppDate.dayAndTime(pickupTime) }
        return PastOrder.estimatedReady(for: fulfillment)
    }

    private var summaryCard: some View {
        VStack(spacing: 14) {
            summaryRow(String(format: localized(controller.cartCount == 1 ? "%lld item" : "%lld items"),
                              controller.cartCount),
                       controller.cartTotal.asPHP)
            if discount > 0 {
                summaryRow("Free drink reward", "−" + discount.asPHP)
            }
            summaryRow(fulfillment.timeLabel, readyText, emphasised: true)

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
    /// trailing control. The heading and lines are looked up as translation
    /// keys, so fixed prompts translate and the customer's own details don't.
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
                Text(LocalizedStringKey(title))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.matchaDarkGreen)
                ForEach(lines, id: \.self) { line in
                    Text(LocalizedStringKey(line))
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
            Text(LocalizedStringKey(label))
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
