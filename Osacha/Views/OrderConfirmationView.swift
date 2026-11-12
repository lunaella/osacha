// Receipt shown after an order is placed.

import SwiftUI

struct OrderConfirmationView: View {
    let order: PastOrder

    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var navigator: NavigationCoordinator

    @State private var showTracking = false
    @State private var askForLocation = false

    /// This order as the session has it now, so a cancellation shows.
    private var current: PastOrder {
        session.orders.first { $0.id == order.id } ?? order
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if current.status == .cancelled {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.red.opacity(0.75))
                        .padding(.top, 40)
                } else {
                    PlacedCheck()
                        .padding(.top, 40)
                }

                (current.status == .cancelled ? Text("Order Cancelled") : Text("Order Placed!"))
                    .font(.title.bold())
                    .foregroundStyle(Color.matchaDarkGreen)

                Text(caption)
                    .font(.subheadline)
                    .foregroundStyle(Color.matchaDarkGreen.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                OrderReceipt(order: current, showsProgress: false)
                    .padding(.top, 8)

                // The order just earned a stamp, so press it onto the card
                // here rather than leaving the customer to find it later.
                if order.earnsStamp && current.status != .cancelled {
                    StampCelebration()
                        .padding(.horizontal, 4)
                }

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

                if current.canCancel(at: session.now) {
                    // Cancelling lands on tracking, which shows it called off.
                    CancelOrderButton(order: current) { showTracking = true }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        // The same green as tracking, which this screen leads into.
        .background(Color.matchaSage.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        // The receipt is a full-screen moment in the design, with no tab bar.
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(isPresented: $showTracking) {
            TrackOrderView(order: order)
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

    private var caption: LocalizedStringKey {
        if current.status == .cancelled {
            return "You haven't been charged."
        }
        if order.scheduledFor != nil {
            return "Your pickup is booked. We'll start whisking just before you arrive."
        }
        return order.method == .delivery
            ? "Whisking your order now. It'll be at your door before you can say matcha."
            : "Whisking your order now. Your matcha will be ready in a whisk."
    }
}

/// The back of the stamp card with this order's gold star pressed onto it:
/// it drops in and lands with a thump once the card scrolls into view. When
/// the stamp fills the card, the free matcha is announced with it.
private struct StampCelebration: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var navigator: NavigationCoordinator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var started = false
    @State private var landed = false

    /// A stamp that filled the card leaves it reset to none, so show it full.
    private var completedCard: Bool { session.loyalty.stamps == 0 }
    private var filled: Int {
        completedCard ? LoyaltyCard.stampsPerReward : session.loyalty.stamps
    }

    var body: some View {
        Button {
            navigator.openLoyaltyCard()
        } label: {
            VStack(spacing: 14) {
                card

                VStack(spacing: 4) {
                    (completedCard ? Text("Card complete!") : Text("+1 stamp on your card"))
                        .font(.headline)
                    (completedCard
                        ? Text("Your 10th matcha is on us — use it at checkout.")
                        : Text("\(session.loyalty.stampsRemaining) more and your 10th matcha is on us."))
                        .font(.subheadline)
                        .opacity(0.75)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(Color.matchaDarkGreen)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.matchaCardCream))
        }
        .buttonStyle(.plain)
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { startIfVisible(proxy.frame(in: .global)) }
                    .onChange(of: proxy.frame(in: .global).minY) { _ in
                        startIfVisible(proxy.frame(in: .global))
                    }
            }
        }
    }

    private var card: some View {
        Image("LoyaltyCardBack")
            .resizable()
            .aspectRatio(LoyaltyCardView.artworkSize, contentMode: .fit)
            .overlay {
                GeometryReader { proxy in
                    let scale = proxy.size.width / LoyaltyCardView.artworkSize.width
                    let side = LoyaltyCardView.stampSide * scale
                    ForEach(0..<min(filled, LoyaltyCardView.slotCenters.count), id: \.self) { index in
                        let center = LoyaltyCardView.slotCenters[index]
                        let isNew = index == filled - 1
                        Image("LoyaltyStamp")
                            .resizable()
                            .scaledToFit()
                            .frame(width: side, height: side)
                            .scaleEffect(isNew && !landed ? 2.6 : 1)
                            .rotationEffect(.degrees(isNew && !landed ? -40 : 0))
                            .opacity(isNew && !landed ? 0 : 1)
                            .shadow(color: .black.opacity(isNew && !landed ? 0.35 : 0), radius: 12, y: 10)
                            .position(x: center.x * scale, y: center.y * scale)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.14), radius: 10, y: 5)
            .accessibilityLabel(Text("Stamp card back, \(filled) of \(LoyaltyCard.stampsPerReward) stamps collected"))
    }

    /// Stamps once, when the whole card can be seen.
    private func startIfVisible(_ frame: CGRect) {
        guard !started, frame.maxY > 0, frame.maxY < UIScreen.main.bounds.height - 40 else { return }
        started = true
        if reduceMotion {
            landed = true
            return
        }
        Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            withAnimation(.spring(response: 0.38, dampingFraction: 0.6)) { landed = true }
            try? await Task.sleep(nanoseconds: 220_000_000)
            Haptics.stamp()
            if completedCard {
                try? await Task.sleep(nanoseconds: 300_000_000)
                Haptics.success()
            }
        }
    }
}

/// The tick that greets a placed order: the circle pops in, the check draws
/// itself, and a ring ripples out once.
private struct PlacedCheck: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var circleScale: CGFloat = 0.4
    @State private var drawn: CGFloat = 0
    @State private var ripple = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.matchaGreen, lineWidth: 3)
                .scaleEffect(ripple ? 1.45 : 1)
                .opacity(ripple ? 0 : 0.6)

            Circle()
                .fill(Color.matchaGreen)
                .shadow(color: Color.matchaGreen.opacity(0.3), radius: 18, y: 8)
                .scaleEffect(circleScale)

            CheckShape()
                .trim(from: 0, to: drawn)
                .stroke(.white, style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
                .frame(width: 50, height: 38)
        }
        .frame(width: 120, height: 120)
        .accessibilityHidden(true)
        .task { await play() }
    }

    private func play() async {
        guard drawn == 0 else { return }
        if reduceMotion {
            circleScale = 1
            drawn = 1
            return
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) { circleScale = 1 }
        try? await Task.sleep(nanoseconds: 250_000_000)
        withAnimation(.easeOut(duration: 0.4)) { drawn = 1 }
        try? await Task.sleep(nanoseconds: 300_000_000)
        withAnimation(.easeOut(duration: 0.9)) { ripple = true }
    }
}

private struct CheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width * 0.38, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

#Preview {
    NavigationStack {
        OrderConfirmationView(order: PastOrder.samples[0])
    }
    .environmentObject(AppSession())
    .environmentObject(NavigationCoordinator())
}
