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
                PlacedCheck()
                    .padding(.top, 40)

                Text("Order Placed!")
                    .font(.title.bold())
                    .foregroundStyle(Color.matchaDarkGreen)

                Text(caption)
                    .font(.subheadline)
                    .foregroundStyle(Color.matchaDarkGreen.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                OrderReceipt(order: order, showsProgress: false)
                    .padding(.top, 8)

                // The order just earned a stamp, so say so here rather than
                // leaving the customer to find it on the card.
                if order.earnsStamp {
                    Button {
                        navigator.openLoyaltyCard()
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
                            .fill(Color.matchaCardCream))
                        .padding(.horizontal)
                    }
                    .buttonStyle(.plain)
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
        if order.scheduledFor != nil {
            return "Your pickup is booked. We'll start whisking just before you arrive."
        }
        return order.method == .delivery
            ? "Whisking your order now. It'll be at your door before you can say matcha."
            : "Whisking your order now. Your matcha will be ready in a whisk."
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
