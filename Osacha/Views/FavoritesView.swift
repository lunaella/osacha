//
//  FavoritesView.swift
//  Osacha
//
//  Lists every menu item the customer has favorited.
//

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var controller: OrderController

    var body: some View {
        VStack {
            if controller.favoriteItems.isEmpty {
                Spacer()
                Text("🤍")
                    .font(.system(size: 56))
                Text("No favorites yet")
                    .font(.headline)
                    .foregroundStyle(Color.matchaDarkGreen)
                    .padding(.top, 8)
                Text("Tap the heart on any item to save it here.")
                    .font(.subheadline)
                    .foregroundStyle(Color.matchaDarkGreen.opacity(0.7))
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(controller.favoriteItems) { item in
                            NavigationLink(value: item) {
                                MenuItemRowView(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.matchaSage.ignoresSafeArea())
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.matchaSageDeep, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationDestination(for: MatchaItem.self) { item in
            ProductDetailView(item: item, items: controller.favoriteItems)
        }
    }
}

#Preview {
    NavigationStack {
        FavoritesView()
    }
    .environmentObject(OrderController())
}
