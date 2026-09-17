//
//  LoyaltyCardView.swift
//  Osacha
//
//  The cafe's stamp card. The printed card artwork flips between its front
//  and its back, where a star sticker lands on the next slot with each order;
//  below it sits the member QR code the counter scans.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct LoyaltyCardView: View {
    @EnvironmentObject private var session: AppSession

    /// Which face of the card is showing.
    @State private var showingBack = false

    /// Pixel size of the card artwork, used for its proportions and to turn
    /// the measured slot positions below into fractions of the card.
    private static let artworkSize = CGSize(width: 1748, height: 1240)

    /// Centres of the nine stampable slots on the back artwork, in artwork
    /// pixels: top row left to right, then the bottom row. The tenth slot
    /// carries the printed bowl and is the free matcha, so it never takes one.
    private static let slotCenters: [CGPoint] = {
        let columns: [CGFloat] = [255, 564, 873, 1182, 1491]
        let rows: [CGFloat] = [465, 823]
        return Array(rows.flatMap { y in columns.map { CGPoint(x: $0, y: y) } }
            .prefix(LoyaltyCard.stampsPerReward))
    }()

    /// Side of the sticker image in artwork pixels. The star fills 1251 of the
    /// image's 2000px, so this makes the star 286px — overhanging its 260px
    /// slot slightly, as on the printed sample.
    private static let stampSide: CGFloat = 457

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                card
                    .padding(.horizontal)
                    .padding(.top, 12)

                Button {
                    flip()
                } label: {
                    Label(showingBack ? "Show front" : "Show stamps",
                          systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.matchaGreen)
                }
                .buttonStyle(.plain)

                progress

                qrPanel

                if session.loyalty.rewardsEarned > 0 {
                    rewardsNote
                }
            }
            .padding(.bottom, 28)
        }
        .background(Color.matchaCream.ignoresSafeArea())
        .navigationTitle("Loyalty Card")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - The card

    /// Both faces sit in the same space; the container rotates and each face
    /// is revealed at the halfway point so neither shows through mirrored.
    private var card: some View {
        ZStack {
            cardFront
                .opacity(showingBack ? 0 : 1)

            cardBack
                .opacity(showingBack ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }
        .rotation3DEffect(.degrees(showingBack ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .onTapGesture { flip() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(showingBack
            ? "Stamp card back, \(session.loyalty.stamps) of \(LoyaltyCard.stampsPerReward) stamps collected"
            : "Osacha loyalty card, front")
        .accessibilityHint("Double tap to turn the card over")
    }

    private var cardFront: some View {
        Image("LoyaltyCardFront")
            .resizable()
            .aspectRatio(Self.artworkSize, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
    }

    private var cardBack: some View {
        Image("LoyaltyCardBack")
            .resizable()
            .aspectRatio(Self.artworkSize, contentMode: .fit)
            .overlay {
                GeometryReader { proxy in
                    // Artwork pixels to on-screen points at the current size.
                    let scale = proxy.size.width / Self.artworkSize.width
                    ForEach(0..<min(session.loyalty.stamps, Self.slotCenters.count), id: \.self) { index in
                        let center = Self.slotCenters[index]
                        Image("LoyaltyStamp")
                            .resizable()
                            .scaledToFit()
                            .frame(width: Self.stampSide * scale, height: Self.stampSide * scale)
                            .position(x: center.x * scale, y: center.y * scale)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.14), radius: 12, y: 6)
    }

    // MARK: - Supporting panels

    private var progress: some View {
        VStack(spacing: 6) {
            Text("\(session.loyalty.stamps) of \(LoyaltyCard.stampsPerReward) stamps")
                .font(.headline)
                .foregroundStyle(Color.matchaDarkGreen)

            Text(session.loyalty.stamps == 0
                 ? "Order something to earn your first stamp."
                 : "\(session.loyalty.stampsRemaining) more and your 10th matcha is on us.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var qrPanel: some View {
        VStack(spacing: 12) {
            Text("Scan at the counter")
                .font(.headline)
                .foregroundStyle(Color.matchaDarkGreen)

            if let qr = Self.qrImage(for: session.loyalty.qrPayload) {
                Image(uiImage: qr)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 168, height: 168)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white))
            }

            Text("A stamp is added to your card with every order.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.matchaCardCream)
        )
        .padding(.horizontal)
    }

    private var rewardsNote: some View {
        Label("\(session.loyalty.rewardsEarned) free drink\(session.loyalty.rewardsEarned == 1 ? "" : "s") earned",
              systemImage: "gift.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.matchaDarkGreen)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.matchaSage.opacity(0.55)))
    }

    private func flip() {
        withAnimation(.easeInOut(duration: 0.55)) {
            showingBack.toggle()
        }
    }

    // MARK: - QR

    /// Renders the member code as a QR image. Generated on device, so the
    /// card works with no network.
    private static func qrImage(for payload: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }

        // The filter emits roughly one pixel per module, which would render
        // as a blur once scaled up to the frame.
        let enlarged = output.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        guard let cgImage = CIContext().createCGImage(enlarged, from: enlarged.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

#Preview {
    NavigationStack {
        LoyaltyCardView()
    }
    .environmentObject(AppSession())
}
