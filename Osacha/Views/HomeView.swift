//
//  HomeView.swift
//  Osacha
//
//  Welcome screen with a shortcut into each menu category.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var session: AppSession

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    /// Guests have no name to greet, and have not been here before as far as
    /// the app knows, so they get the neutral welcome instead of "back".
    private var greeting: Text {
        session.isSignedIn
            ? Text("Hello \(session.profile.firstName),\nWelcome back!")
            : Text("Hello there,\nWelcome to Osacha!")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image("OsachaLogoGreen")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .padding(.top, 12)

                greeting
                    .font(.title2.bold())
                    .foregroundStyle(Color.matchaDarkGreen)
                    .multilineTextAlignment(.center)

                cafeStatus

                // A finished order the customer hasn't said anything about yet.
                if session.isSignedIn, let order = session.orderAwaitingRating {
                    RateOrderPrompt(order: order)
                        .padding(.horizontal)
                        // The category photos rise above their cards.
                        .padding(.bottom, 16)
                }

                // The category images rise above their cards, so the grid
                // needs that height back to keep clear of the greeting.
                // Each card's photo rises above its top edge, so rows need
                // that much extra room or the second row's photos sit on the
                // first row's cards. Matches the 46pt row gap in the design.
                LazyVGrid(columns: columns, spacing: 46) {
                    ForEach(MatchaCategory.allCases) { category in
                        NavigationLink(value: category) {
                            CategoryCardView(category: category)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 30)
                .padding(.horizontal)
            }
            .padding(.bottom, 24)
        }
        .background(MatchaBackground())
        // The logo in the scroll content is the brand mark here, so the nav
        // bar stays empty rather than repeating the name.
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: MatchaCategory.self) { category in
            MenuView(category: category)
        }
    }

    /// Whether the café is open, and until when or from when.
    private var cafeStatus: some View {
        let open = Cafe.isOpen(at: session.now)
        return HStack(spacing: 8) {
            Circle()
                .fill(open ? Color.matchaGreen : Color.matchaPinkDeep)
                .frame(width: 8, height: 8)
            Text(Cafe.statusText(at: session.now))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.matchaDarkGreen)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Capsule().fill(Color.matchaCardCream.opacity(0.9)))
        .accessibilityElement(children: .combine)
    }

}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environmentObject(OrderController())
    .environmentObject(AppSession())
}
