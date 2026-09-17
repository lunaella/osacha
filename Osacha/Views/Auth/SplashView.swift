//
//  SplashView.swift
//  Osacha
//
//  Opening screen. Uses the same background as the home screen so the hand-off
//  is seamless, and settles the logo into the position it occupies there.
//

import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var session: AppSession

    @State private var settled = false

    var body: some View {
        ZStack {
            // Matches HomeView's background exactly, so nothing shifts on hand-off.
            MatchaBackground()

            Image("OsachaLogoWhite")
                .resizable()
                .scaledToFit()
                .frame(height: settled ? 120 : 184)
                .offset(y: settled ? -320 : 0)
                .opacity(settled ? 0 : 1)
        }
        .task {
            try? await Task.sleep(nanoseconds: 2_300_000_000)
            withAnimation(.easeInOut(duration: 1.3)) {
                settled = true
            }
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            session.finishLaunching()
        }
    }
}

/// The matcha cup background shared by the splash and home screens.
struct MatchaBackground: View {
    var body: some View {
        // The cream surround and the rounded bowl are part of the photograph,
        // so it is shown at full strength — no wash, no separately drawn shape.
        //
        // The image is given the measured size explicitly. Left unsized, a
        // scaledToFill image overflows its container and centres on *that*
        // container's midpoint, so the splash (laid out against the whole
        // screen) and the home screen (laid out against a scroll view inset by
        // the navigation and tab bars) framed the photo differently and it
        // jumped on the hand-off.
        GeometryReader { proxy in
            Image("HomeBackground")
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
        }
        // A thin cream veil, as in the design — enough to soften the greens
        // without washing them out the way the old 45% overlay did.
        .overlay(Color.matchaCream.opacity(0.18))
        .background(Color.matchaCream)
        .ignoresSafeArea()
    }
}

#Preview {
    SplashView()
        .environmentObject(AppSession())
}
