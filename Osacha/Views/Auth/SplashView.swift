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
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            withAnimation(.easeInOut(duration: 0.9)) {
                settled = true
            }
            try? await Task.sleep(nanoseconds: 750_000_000)
            session.finishLaunching()
        }
    }
}

/// The matcha cup background shared by the splash and home screens.
struct MatchaBackground: View {
    var body: some View {
        ZStack {
            Color.matchaCream
            Image("HomeBackground")
                .resizable()
                .scaledToFill()
            Color.matchaCream.opacity(0.45)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    SplashView()
        .environmentObject(AppSession())
}
