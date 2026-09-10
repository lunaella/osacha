//
//  OrderController.swift
//  Osacha
//
//  Controller layer: owns the menu catalog, cart, favorites, and search
//  state; mediates every mutation the views can request; persists cart
//  and favorites to disk. Views never touch storage directly.
//

import Foundation
import Combine

@MainActor
final class OrderController: ObservableObject {
    @Published private(set) var items: [MatchaItem] = MatchaItem.sampleItems
    @Published private(set) var cart: [CartEntry] = []
    @Published private(set) var favoriteIDs: Set<UUID> = []
    @Published var searchText: String = ""

    private let cartKey = "matchaCafe.cart"
    private let favoritesKey = "matchaCafe.favorites"

    init() {
        loadFavorites()
        loadCart()
    }

    // MARK: - Catalog queries

    func items(in category: MatchaCategory) -> [MatchaItem] {
        let categoryItems = items.filter { $0.category == category }
        guard !searchText.isEmpty else { return categoryItems }
        return categoryItems.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var searchResults: [MatchaItem] {
        guard !searchText.isEmpty else { return items }
        return items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: - Favorites

    func isFavorite(_ item: MatchaItem) -> Bool {
        favoriteIDs.contains(item.id)
    }

    func toggleFavorite(_ item: MatchaItem) {
        if favoriteIDs.contains(item.id) {
            favoriteIDs.remove(item.id)
        } else {
            favoriteIDs.insert(item.id)
        }
        saveFavorites()
    }

    var favoriteItems: [MatchaItem] {
        items.filter { favoriteIDs.contains($0.id) }
    }

    // MARK: - Cart

    var cartCount: Int {
        cart.reduce(0) { $0 + $1.quantity }
    }

    var cartTotal: Double {
        cart.reduce(0) { $0 + $1.subtotal }
    }

    func addToCart(item: MatchaItem, size: DrinkSize?, milk: MilkOption?, withIceCream: Bool = false, quantity: Int) {
        let entry = CartEntry(id: UUID(), item: item, size: size, milk: milk, withIceCream: withIceCream, quantity: quantity)
        cart.append(entry)
        saveCart()
    }

    func updateQuantity(for entry: CartEntry, quantity: Int) {
        guard let index = cart.firstIndex(where: { $0.id == entry.id }) else { return }
        if quantity <= 0 {
            cart.remove(at: index)
        } else {
            cart[index].quantity = quantity
        }
        saveCart()
    }

    func removeFromCart(_ entry: CartEntry) {
        cart.removeAll { $0.id == entry.id }
        saveCart()
    }

    func clearCart() {
        cart.removeAll()
        saveCart()
    }

    // MARK: - Persistence

    private func loadCart() {
        guard let data = UserDefaults.standard.data(forKey: cartKey),
              let decoded = try? JSONDecoder().decode([CartEntry].self, from: data) else { return }
        cart = decoded
    }

    private func saveCart() {
        guard let data = try? JSONEncoder().encode(cart) else { return }
        UserDefaults.standard.set(data, forKey: cartKey)
    }

    private func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: favoritesKey),
              let decoded = try? JSONDecoder().decode(Set<UUID>.self, from: data) else { return }
        favoriteIDs = decoded
    }

    private func saveFavorites() {
        guard let data = try? JSONEncoder().encode(favoriteIDs) else { return }
        UserDefaults.standard.set(data, forKey: favoritesKey)
    }
}
