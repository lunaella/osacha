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

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(controller)
                .environmentObject(session)
                .environmentObject(navigator)
                .preferredColorScheme(session.appearance.colorScheme)
        }
    }
}

/// Shows the splash while the app "starts up", then hands over to the app itself.
private struct RootView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        if session.hasLaunched {
            ContentView()
                .transition(.opacity)
        } else {
            SplashView()
        }
    }
}
