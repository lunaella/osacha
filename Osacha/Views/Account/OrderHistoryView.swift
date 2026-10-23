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

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(session.orders) { order in
                    // Orders still on their way open to their tracking
                    // details; finished ones have nothing left to follow.
                    if order.status.isFinished {
                        row(order)
                    } else {
                        NavigationLink {
                            TrackOrderView(order: order)
                        } label: {
                            row(order)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .accountBackground()
        .navigationTitle("Order History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ order: PastOrder) -> some View {
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

            VStack(alignment: .trailing, spacing: 8) {
                Text(order.status.rawValue)
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
        .accountCard()
    }
}

private extension OrderStatus {
    var isFinished: Bool { self == .completed || self == .delivered }

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

/// Follows one order on its printed receipt. The full history is a tap away
/// in the toolbar, so it doesn't crowd out what the customer is waiting on.
struct TrackOrderView: View {
    let order: PastOrder

    var body: some View {
        ScrollView {
            OrderReceipt(order: order)
                .padding()
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

    /// The stages this order moves through, in order.
    private var stages: [OrderStatus] {
        order.method == .pickup ? [.preparing, .ready, .completed] : [.preparing, .outForDelivery, .delivered]
    }

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
                infoRow("Date:", order.placedAt)
                infoRow("Order:", "#\(order.reference)")
                infoRow("Method:", order.method == .pickup ? "Pickup" : "Delivery")
                infoRow(order.method == .pickup ? "Ready:" : "Arrives:", order.readyAt)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ReceiptRule()

            HStack {
                Text("Status:")
                Spacer()
                Text(order.status.rawValue.uppercased())
                    .fontWeight(.bold)
            }
            .font(.system(.subheadline, design: .monospaced))

            ReceiptBarcode(code: order.reference)
                .frame(height: 64)

            VStack(spacing: 12) {
                if let lines = order.lines, !lines.isEmpty {
                    ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                        leaderRow(line.name, String(format: "x%02d", line.quantity))
                    }
                } else {
                    leaderRow("Items", String(format: "x%02d", order.itemCount))
                }
            }
            .padding(.top, 4)

            ReceiptRule()

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
                            Text(stage.rawValue.uppercased())
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

            VStack(spacing: 4) {
                Text("THANK YOU")
                    .kerning(10)
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

    private func infoRow(_ label: String, _ value: String) -> some View {
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
    var title: String?

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

#Preview("Track Order") {
    NavigationStack { TrackOrderView(order: PastOrder.samples[0]) }
        .environmentObject(AppSession())
}
