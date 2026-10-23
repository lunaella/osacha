//
//  OsachaApp.swift
//  Osacha
//
//  Entry point of the application.
//

import SwiftUI

@main
struct OsachaApp: App {
    @StateObject private var controller = OrderController()
    @StateObject private var session = AppSession()
    @StateObject private var navigator = NavigationCoordinator()

    init() {
        Bundle.followAppLanguage()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(controller)
                .environmentObject(session)
                .environmentObject(navigator)
                // Every screen is drawn on fixed light backgrounds, so system
                // text colours must stay dark too. Following a phone set to
                // Dark Mode turned body text white on cream and unreadable.
                .preferredColorScheme(.light)
                .task { NotificationScheduler.shared.start(navigator: navigator) }
        }
    }
}

/// Shows the splash while the app "starts up", then hands over to the app itself.
private struct RootView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        Group {
            if session.hasLaunched {
                ContentView()
                    .transition(.opacity)
            } else {
                SplashView()
            }
        }
        // Changing the locale makes every Text look its words up again, so
        // switching language in Settings rewrites the whole app in place.
        .environment(\.locale, session.language.locale)
    }
}
