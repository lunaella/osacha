//
//  HomeView.swift
//  Osacha
//
//  Welcome screen with a shortcut into each menu category.
//

import SwiftUI

struct HomeView: View {
    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image("OsachaLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .padding(.top, 12)

                Text("Hello friend,\nWelcome back!")
                    .font(.title2.bold())
                    .foregroundStyle(Color.matchaDarkGreen)
                    .multilineTextAlignment(.center)

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(MatchaCategory.allCases) { category in
                        NavigationLink(value: category) {
                            CategoryCardView(category: category)
                        }
                        .buttonStyle(.plain)
                    }
                }
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
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environmentObject(OrderController())
}
