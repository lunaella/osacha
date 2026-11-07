//
//  WhiskingLogo.swift
//  Osacha
//
//  The Osacha bowl with its whisk going: a couple of seconds of quick
//  strokes side to side, a rest, then again. The artwork comes as two
//  images on the same canvas, everything that stays still and the whisk on
//  its own, and the whisk swings from the top of its handle, the way a hand
//  holds it. Still when Reduce Motion is on.
//

import SwiftUI

struct WhiskingLogo: View {
    /// The artwork without its whisk.
    let still: String
    /// The whisk alone, on the same canvas as `still`.
    let whisk: String
    /// Where the hand holds the whisk, as a point in the artwork.
    let grip: UnitPoint

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let maxAngle = 5.0        // degrees either side
    private static let strokesPerSecond = 4.0
    private static let whiskFor = 1.6        // seconds of whisking
    private static let restFor = 1.2         // seconds of rest

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            ZStack {
                Image(still).resizable().scaledToFit()
                Image(whisk).resizable().scaledToFit()
                    .rotationEffect(.degrees(reduceMotion ? 0 : angle(at: context.date)), anchor: grip)
            }
        }
    }

    private func angle(at date: Date) -> Double {
        let t = date.timeIntervalSinceReferenceDate
            .truncatingRemainder(dividingBy: Self.whiskFor + Self.restFor)
        guard t < Self.whiskFor else { return 0 }
        // Eases into the strokes and out of them, so it never jumps.
        let envelope = sin(.pi * t / Self.whiskFor)
        return Self.maxAngle * envelope * sin(2 * .pi * Self.strokesPerSecond * t)
    }
}
