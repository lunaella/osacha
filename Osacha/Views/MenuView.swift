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
                    Image(systemName: "cart.fill")
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
