//
//  MenuView.swift
//  Osacha
//
//  Lists the items in one category, or across the whole menu when no
//  category is given (used by the Search tab), with a live search field.
//

import SwiftUI

struct MenuView: View {
    let category: MatchaCategory?

    @EnvironmentObject private var controller: OrderController

    /// Count of everything in the cart, sitting on the corner of the cart
    /// icon. Hidden when empty so the toolbar stays quiet.
    ///
    /// Capped at "9+" so it stays a fixed-size circle: a widening capsule
    /// grew leftward across the cart glyph and read as clutter on a button
    /// this small.
    @ViewBuilder
    private var cartBadge: some View {
        if controller.cartCount > 0 {
            Text(controller.cartCount > 9 ? "9+" : "\(controller.cartCount)")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 14, height: 14)
                .background(Circle().fill(Color.matchaPinkDeep))
                .offset(x: 7, y: -7)
        }
    }

    private var results: [MatchaItem] {
        if let category {
            return controller.items(in: category)
        }
        return controller.searchResults
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search matcha drinks & treats", text: $controller.searchText)
                    .autocorrectionDisabled()
                if !controller.searchText.isEmpty {
                    Button {
                        controller.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.matchaCardCream))
            .padding([.horizontal, .top])
            .padding(.bottom, 12)

            if results.isEmpty {
                Spacer()
                Text("No items found")
                    .foregroundStyle(Color.matchaDarkGreen.opacity(0.7))
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(results) { item in
                            NavigationLink(value: item) {
                                MenuItemRowView(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.matchaSage.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // The brand mark replaces the written category title.
            ToolbarItem(placement: .principal) {
                Image("OsachaLogoMenu")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 38)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(value: CartRoute()) {
                    // Deliberately smaller than the toolbar default so the
                    // badge has room to read on its own.
                    Image(systemName: "cart.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .overlay(alignment: .topTrailing) { cartBadge }
                }
            }
        }
        .navigationDestination(for: MatchaItem.self) { item in
            ProductDetailView(item: item, items: results)
        }
        .navigationDestination(for: CartRoute.self) { _ in
            CartView()
        }
        .toolbarBackground(Color.matchaSageDeep, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
    }
}

/// Marker type used to push the cart screen via `navigationDestination`.
struct CartRoute: Hashable {}

#Preview {
    NavigationStack {
        MenuView(category: .drinks)
    }
    .environmentObject(OrderController())
}
