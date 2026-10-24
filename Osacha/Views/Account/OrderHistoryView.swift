//
//  OrderHistoryView.swift
//  Osacha
//
//  Past orders, newest first.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct OrderHistoryView: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var controller: OrderController

    @State private var rating: PastOrder?
    /// How many items the last reorder put in the cart, for the banner.
    @State private var reordered: Int?
    @State private var showCart = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(session.orders) { order in
                    // Orders still on their way open to their tracking
                    // details; finished ones can be ordered again or rated.
                    if order.status.isFinished {
                        VStack(spacing: 0) {
                            row(order)
                            if order.canReorder || order.placedDate != nil {
                                actions(order)
                            }
                        }
                        .accountCard()
                    } else {
                        NavigationLink {
                            TrackOrderView(order: order)
                        } label: {
                            row(order)
                                .accountCard()
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
            .padding(.bottom, reordered == nil ? 0 : 70)
        }
        .accountBackground()
        .navigationTitle("Order History")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            if let reordered {
                reorderBanner(reordered)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(item: $rating) { order in
            RateOrderView(order: order)
        }
        .navigationDestination(isPresented: $showCart) {
            CartView()
        }
    }

    private func row(_ order: PastOrder) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Order #\(order.reference)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.matchaDarkGreen)
                Text(order.placedAtText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(order.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Text(LocalizedStringKey(order.status.rawValue))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(order.status.foreground)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(order.status.background))

                if !order.status.isFinished {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.matchaGreen)
                }
            }
        }
        .padding(16)
        .contentShape(Rectangle())
    }

    /// Order again, and the rating — given, or a button to give one.
    private func actions(_ order: PastOrder) -> some View {
        HStack(spacing: 10) {
            if let stars = order.rating {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { value in
                        Image(systemName: value <= stars ? "star.fill" : "star")
                    }
                }
                .font(.caption)
                .foregroundStyle(Color.matchaPinkDeep)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Rated \(stars) of 5 stars"))
            } else if order.placedDate != nil {
                Button {
                    rating = order
                } label: {
                    Label("Rate", systemImage: "star")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.matchaPinkDeep)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .overlay(Capsule().stroke(Color.matchaPinkDeep, lineWidth: 1.2))
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if order.canReorder {
                Button {
                    let added = controller.reorder(order)
                    withAnimation(.spring(response: 0.35)) { reordered = added }
                } label: {
                    Label("Reorder", systemImage: "arrow.clockwise")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Color.matchaGreen))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }

    private func reorderBanner(_ count: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "cart.fill.badge.plus")
            (count == 1 ? Text("1 item added to your cart") : Text("\(count) items added to your cart"))
                .font(.subheadline.weight(.semibold))
            Spacer()
            Button {
                showCart = true
                reordered = nil
            } label: {
                Text("View cart")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.matchaGreen)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(.white))
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.matchaGreen))
        .padding()
    }
}

private extension OrderStatus {
    var foreground: Color {
        switch self {
        case .scheduled, .preparing: return Color.matchaPinkDeep
        case .ready, .outForDelivery: return Color.matchaDarkGreen
        case .completed, .delivered: return Color.matchaGreen
        }
    }

    var background: Color {
        switch self {
        case .scheduled, .preparing: return Color.matchaPinkPale
        case .ready, .outForDelivery: return Color.matchaSage
        case .completed, .delivered: return Color.matchaSage.opacity(0.45)
        }
    }
}

/// Follows one order: where it is now first, then what was in it. The
/// receipt was already printed on the confirmation, so here it stays folded
/// away until asked for. The full history is a tap away in the toolbar.
struct TrackOrderView: View {
    let order: PastOrder

    @EnvironmentObject private var session: AppSession
    @State private var showsReceipt = false

    /// This order as the session has it now, so a rating shows once given.
    private var current: PastOrder {
        session.orders.first { $0.id == order.id } ?? order
    }

    var body: some View {
        // Reading the clock moves the screen on as the order does.
        let _ = session.now
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if current.method == .delivery, current.placedDate != nil {
                    RiderTrackingView(order: current)
                } else if current.method == .pickup {
                    CafeMapView()
                }

                section("Order status") {
                    statusCard
                    if current.awaitsRating {
                        RateOrderPrompt(order: current)
                    }
                }

                section("Order details") {
                    detailsCard
                    if showsReceipt {
                        OrderReceipt(order: current, showsProgress: false)
                            .transition(.opacity)
                    }
                }
            }
            .padding()
            .animation(.easeInOut(duration: 0.25), value: showsReceipt)
        }
        .background(Color.matchaSage.ignoresSafeArea())
        .toolbarBackground(Color.matchaSageDeep, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationTitle("Track Order")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    OrderHistoryView()
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(Color.matchaGreen)
                }
                .accessibilityLabel("Order History")
            }
        }
    }

    /// A titled block with a rule above it, so the map, the status and the
    /// order read as separate parts of the screen.
    private func section<Content: View>(_ title: LocalizedStringKey,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.matchaDarkGreen)
                Rectangle()
                    .fill(Color.matchaDarkGreen.opacity(0.2))
                    .frame(height: 1)
            }
            content()
        }
    }

    // MARK: - Status

    private var statusCard: some View {
        let stages = current.stages
        let reached = stages.firstIndex(of: current.status) ?? 0

        return VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                Image(systemName: current.status.symbol)
                    .font(.title3)
                    .foregroundStyle(current.status.foreground)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(current.status.background))
                VStack(alignment: .leading, spacing: 3) {
                    Text(LocalizedStringKey(current.status.rawValue))
                        .font(.title3.bold())
                    Text(statusDetail)
                        .font(.subheadline)
                        .opacity(0.7)
                }
                .foregroundStyle(Color.matchaDarkGreen)
            }

            // One step per stage, filled in up to where the order is.
            HStack(alignment: .top, spacing: 6) {
                ForEach(Array(stages.enumerated()), id: \.element) { index, stage in
                    VStack(alignment: .leading, spacing: 6) {
                        Capsule()
                            .fill(index <= reached ? Color.matchaGreen : Color.matchaDarkGreen.opacity(0.15))
                            .frame(height: 6)
                        Text(LocalizedStringKey(stage.rawValue))
                            .font(.caption2.weight(index == reached ? .bold : .regular))
                            .foregroundStyle(Color.matchaDarkGreen.opacity(index <= reached ? 1 : 0.5))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.matchaCardCream))
    }

    /// What the customer is waiting for, in a line.
    private var statusDetail: String {
        let time = current.readyDate.map(AppDate.time) ?? current.readyAt
        switch current.status {
        case .scheduled: return String(format: localized("Pickup at %@"), time)
        case .preparing:
            return String(format: localized(current.method == .delivery ? "Arrives about %@" : "Ready about %@"), time)
        case .outForDelivery: return String(format: localized("Arrives about %@"), time)
        case .ready: return localized("Waiting for you at the counter")
        case .completed, .delivered: return localized("Thanks for ordering!")
        }
    }

    // MARK: - Details

    private var detailsCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Order #\(current.reference)")
                        .font(.subheadline.weight(.semibold))
                    Text(current.placedAtText)
                        .font(.caption)
                        .opacity(0.7)
                    Text(current.summary)
                        .font(.caption)
                        .opacity(0.7)
                }
                Spacer()
                Text(LocalizedStringKey(current.method.rawValue))
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.matchaSage))
            }
            .foregroundStyle(Color.matchaDarkGreen)
            .padding(16)

            Divider()

            Button {
                showsReceipt.toggle()
            } label: {
                HStack {
                    Image(systemName: "doc.plaintext")
                    Text(showsReceipt ? "Hide receipt" : "Show receipt")
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(showsReceipt ? 180 : 0))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.matchaGreen)
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.matchaCardCream))
    }
}

private extension OrderStatus {
    var symbol: String {
        switch self {
        case .scheduled: return "calendar.badge.clock"
        case .preparing: return "cup.and.saucer.fill"
        case .ready: return "bag.fill"
        case .outForDelivery: return "bicycle"
        case .completed, .delivered: return "checkmark.circle.fill"
        }
    }
}

/// An order laid out like a till receipt, feeding out of a printer slot the
/// first time it appears. Shared by the order confirmation and tracking.
struct OrderReceipt: View {
    let order: PastOrder
    /// The step-by-step progress, left off where tracking is one tap away.
    var showsProgress = true

    @EnvironmentObject private var session: AppSession

    private static let ink = Color.matchaCardBorder

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How much of the receipt has fed out of the printer, from 0 to 1.
    @State private var printed: CGFloat = 0
    @State private var paperHeight: CGFloat = 1000

    private var stages: [OrderStatus] { order.stages }

    var body: some View {
        // Reading the session clock redraws the stages as the order moves on.
        let _ = session.now
        let current = stages.firstIndex(of: order.status) ?? 0

        VStack(spacing: 16) {
            Image("OsachaLogoGreen")
                .resizable()
                .scaledToFit()
                .frame(height: 90)
                .padding(.top, 8)

            ReceiptRule(title: "ORDER RECEIPT")

            VStack(alignment: .leading, spacing: 4) {
                infoRow("Date:", order.placedAtText)
                infoRow("Order:", "#\(order.reference)")
                infoRow("Method:", localized(order.method.rawValue))
                infoRow(order.method == .delivery ? "Arrives:" : order.scheduledFor == nil ? "Ready:" : "Pickup:",
                        order.readyAt)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ReceiptRule()

            HStack {
                Text("Status:")
                Spacer()
                Text(localized(order.status.rawValue).uppercased())
                    .fontWeight(.bold)
            }
            .font(.system(.subheadline, design: .monospaced))

            ReceiptBarcode(code: order.reference)
                .frame(height: 64)

            VStack(spacing: 12) {
                if let lines = order.lines, !lines.isEmpty {
                    ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                        VStack(alignment: .leading, spacing: 2) {
                            leaderRow(line.name, String(format: "x%02d", line.quantity))
                            if !line.options.isEmpty {
                                Text(line.options)
                                    .font(.system(.caption, design: .monospaced))
                                    .opacity(0.7)
                            }
                        }
                    }
                } else {
                    leaderRow(localized("Items"), String(format: "x%02d", order.itemCount))
                }
            }
            .padding(.top, 4)

            if let note = order.note {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("Note:")
                        .frame(width: 90, alignment: .leading)
                    Text(note)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.system(.subheadline, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            ReceiptRule()

            if let discount = order.discount {
                VStack(spacing: 6) {
                    HStack {
                        Text("SUBTOTAL")
                        Spacer()
                        Text(order.subtotal.asPHP)
                    }
                    HStack {
                        Text("FREE DRINK")
                        Spacer()
                        Text("−" + discount.asPHP)
                    }
                }
                .font(.system(.subheadline, design: .monospaced))
            }

            HStack {
                Text("TOTAL")
                Spacer()
                Text(order.total.asPHP)
            }
            .font(.system(.title3, design: .monospaced).weight(.bold))

            if showsProgress {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(stages.enumerated()), id: \.element) { index, stage in
                        HStack(spacing: 10) {
                            Text(index <= current ? "[x]" : "[ ]")
                            Text(localized(stage.rawValue).uppercased())
                                .fontWeight(index == current ? .bold : .regular)
                            Spacer()
                        }
                        .opacity(index <= current ? 1 : 0.45)
                    }
                }
                .font(.system(.subheadline, design: .monospaced))
                .padding(.top, 4)
            }

            ReceiptRule(title: "ORDER #\(order.reference)")
                .padding(.top, 8)

            if let rating = order.rating {
                HStack(spacing: 10) {
                    Text("YOUR RATING")
                    Text(String(repeating: "★", count: rating) + String(repeating: "☆", count: 5 - rating))
                        .foregroundStyle(Color.matchaPinkDeep)
                }
                .font(.system(.subheadline, design: .monospaced).weight(.semibold))
            }

            VStack(spacing: 4) {
                Text("THANK YOU")
                    // Spaced out like a till's banner; Japanese reads
                    // better set close.
                    .kerning(session.language == .english ? 10 : 2)
                Text("ENJOY YOUR MATCHA")
            }
            .font(.system(.subheadline, design: .monospaced).weight(.semibold))
            .padding(.vertical, 8)
        }
        .foregroundStyle(Self.ink)
        .padding(.horizontal, 22)
        .padding(.vertical, 24)
        // Shadow the paper alone, not every logo and bar printed on it.
        .background(Rectangle().fill(Color.matchaPinkPale)
            .shadow(color: .black.opacity(0.12), radius: 12, y: 6))
        .background(GeometryReader { proxy in
            Color.clear.onAppear { paperHeight = proxy.size.height }
        })
        // Slide the paper up behind the slot until it has printed, and
        // hide whatever hasn't come out yet. The mask reaches past the
        // sides and bottom so the shadow isn't cut off.
        .offset(y: -(1 - printed) * paperHeight)
        .mask(Rectangle().padding(EdgeInsets(top: 0, leading: -30, bottom: -40, trailing: -30)))
        .padding(.horizontal, 12)
        // The paper's top edge sits on the slot's black opening, with the
        // slot behind it, so it reads as feeding out of that line.
        .padding(.top, 8)
        .background(alignment: .top) { printerSlot }
        .task { await printReceipt() }
    }

    /// The mouth of the printer the receipt feeds out of.
    private var printerSlot: some View {
        Capsule()
            .fill(Self.ink)
            .frame(height: 16)
            .overlay(Capsule().fill(.black).frame(height: 4).padding(.horizontal, 10))
            .shadow(color: .black.opacity(0.25), radius: 4, y: 3)
    }

    /// Feeds the receipt out in short jerks, the way a till printer does,
    /// and only the first time the screen appears.
    private func printReceipt() async {
        guard printed == 0 else { return }
        if reduceMotion {
            printed = 1
            return
        }
        try? await Task.sleep(nanoseconds: 250_000_000)
        let steps = 12
        for step in 1...steps {
            withAnimation(.easeOut(duration: 0.12)) {
                printed = CGFloat(step) / CGFloat(steps)
            }
            try? await Task.sleep(nanoseconds: 150_000_000)
        }
    }

    private func infoRow(_ label: LocalizedStringKey, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(label)
                .frame(width: 90, alignment: .leading)
            Text(value)
        }
        .font(.system(.subheadline, design: .monospaced))
    }

    /// An item line with a dotted leader running across to its quantity.
    private func leaderRow(_ name: String, _ value: String) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            Text(name)
                .font(.subheadline)
                .layoutPriority(1)
            Line()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [1.5, 4]))
                .frame(height: 1)
                .opacity(0.7)
            Text(value)
                .font(.system(.title3, design: .monospaced))
                .layoutPriority(1)
        }
    }
}

/// A row of asterisks across the receipt, with an optional heading set into it.
private struct ReceiptRule: View {
    var title: LocalizedStringKey?

    var body: some View {
        HStack(spacing: 8) {
            stars
            if let title {
                Text(title)
                    .fixedSize()
                stars
            }
        }
        .font(.system(.footnote, design: .monospaced).weight(.semibold))
    }

    /// Longer than any screen and clipped, so the row always reaches the
    /// edge. It rides in an overlay so its length never widens the receipt.
    private var stars: some View {
        Text("*")
            .hidden()
            .frame(maxWidth: .infinity)
            .overlay(Text(String(repeating: "*", count: 80)).fixedSize())
            .clipped()
    }
}

private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        }
    }
}

/// A real Code 128 barcode of the order reference, so the counter could scan it.
private struct ReceiptBarcode: View {
    let code: String

    var body: some View {
        if let image = Self.render(code) {
            Image(uiImage: image)
                .renderingMode(.template)
                .interpolation(.none)
                .resizable()
        }
    }

    private static func render(_ code: String) -> UIImage? {
        let filter = CIFilter.code128BarcodeGenerator()
        filter.message = Data(code.utf8)
        filter.quietSpace = 0
        // Keep only the bars, so they print in the receipt's ink on its paper.
        guard let bars = filter.outputImage,
              let output = Optional(bars.applyingFilter("CIColorInvert").applyingFilter("CIMaskToAlpha")),
              let cgImage = CIContext().createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

struct NotificationsView: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var navigator: NavigationCoordinator

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
                        // Order updates open the history; the rest are about
                        // the loyalty card, which lives on the Profile tab.
                        if note.kind.isAboutAnOrder {
                            NavigationLink {
                                OrderHistoryView()
                            } label: {
                                row(note)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button {
                                navigator.openLoyaltyCard()
                            } label: {
                                row(note)
                            }
                            .buttonStyle(.plain)
                        }
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
                Text(note.text)
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

}

#Preview {
    NavigationStack { OrderHistoryView() }
        .environmentObject(AppSession())
        .environmentObject(OrderController())
}

#Preview("Track Order") {
    NavigationStack { TrackOrderView(order: PastOrder.samples[0]) }
        .environmentObject(AppSession())
}
