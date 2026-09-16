//
//  ContentView.swift
//  Osacha
//
//  Root container. Signed-in customers get the full four-tab app; guests can
//  browse the menu but see a "Login to Order" bar in place of the tab bar,
//  because ordering is gated behind signing in.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var navigator: NavigationCoordinator
    @State private var showLogin = false

    var body: some View {
        Group {
            if session.isSignedIn {
                memberTabs
            } else {
                guestShell
            }
        }
        .fullScreenCover(isPresented: $showLogin) {
            LoginView()
        }
        // Verifying the code signs the session in from inside the cover, so
        // close it once that happens and let the tab view take over.
        .onChange(of: session.isSignedIn) { signedIn in
            if signedIn { showLogin = false }
        }
    }

    private var memberTabs: some View {
        TabView(selection: $navigator.selectedTab) {
            // Path-driven so the order receipt can pop the whole ordering
            // flow back to the menu root.
            NavigationStack(path: $navigator.homePath) {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(AppTab.home)

            NavigationStack {
                MenuView(category: nil)
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(AppTab.search)

            NavigationStack {
                FavoritesView()
            }
            .tabItem {
                Label("Favorites", systemImage: "heart.fill")
            }
            .tag(AppTab.favorites)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            .tag(AppTab.profile)
        }
        .tint(.matchaGreen)
    }

    private var guestShell: some View {
        ZStack(alignment: .bottom) {
            NavigationStack {
                HomeView()
            }

            Button {
                showLogin = true
            } label: {
                Text("Login to Order")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        Capsule().fill(Color.matchaPinkDeep.opacity(0.95))
                    )
                    .shadow(color: Color.matchaPinkDeep.opacity(0.32), radius: 20, y: 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(OrderController())
        .environmentObject(AppSession())
        .environmentObject(NavigationCoordinator())
}
