//
//  MatchaModels.swift
//  Osacha
//
//  Model layer: pure data describing the menu catalog, order
//  customization options, and cart entries. No app state, no UI.
//

import Foundation

enum MatchaCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case drinks = "Matcha Drinks"
    case desserts = "Matcha Desserts"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .drinks: return "Iced lattes, cloud foams,\nand specialty matcha creations"
        case .desserts: return "Cakes, tiramisu, puddings,\nand matcha sweets"
        }
    }

    /// Asset catalog image used to represent this category on the home screen.
    var previewImageName: String {
        switch self {
        case .drinks: return "matcha cloud tiramisu latte"
        case .desserts: return "matcha fresh cream swiss roll"
        }
    }
}

enum DrinkSize: String, Codable, CaseIterable, Identifiable, Hashable {
    case regular = "Regular"
    case grande = "Grande"
    case venti = "Venti"

    var id: String { rawValue }
}

enum MilkOption: String, Codable, CaseIterable, Identifiable, Hashable {
    case regular = "Regular"
    case oat = "Oat"
    case soy = "Soy"
    case almond = "Almond"

    var id: String { rawValue }

    /// Alternative milks carry an upgrade fee; regular dairy is covered by the base price.
    var surcharge: Double {
        self == .regular ? 0 : 30
    }
}

struct MatchaItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var category: MatchaCategory
    /// Full copy, shown on the product detail screen.
    var itemDescription: String
    /// One-or-two-line copy written for the menu list, so rows read cleanly
    /// instead of truncating the long description mid-sentence.
    var listDescription: String
    /// Base price. For items without per-size pricing, this is the price charged.
    var price: Double
    /// Per-size pricing for items with `hasSizeOptions == true`. Not every item
    /// offers every size (e.g. Usucha and Egg Matcha have no Venti).
    var sizePrices: [DrinkSize: Double] = [:]
    /// Name of the image in Assets.xcassets/Menu that shows this item.
    var imageName: String
    var hasSizeOptions: Bool
    var hasMilkOptions: Bool
    /// Whether this item can be ordered "with ice cream" for an extra fee.
    var hasIceCreamOption: Bool = false
    /// Image shown in place of `imageName` when the ice cream option is selected.
    var iceCreamImageName: String?
    /// Extra fee added when the ice cream option is selected.
    var iceCreamAddOnPrice: Double = 0

    /// The sizes this item is actually offered in, in Regular/Grande/Venti order.
    var availableSizes: [DrinkSize] {
        DrinkSize.allCases.filter { sizePrices[$0] != nil }
    }

    /// Resolves the price for a given size, falling back to the base price.
    func price(for size: DrinkSize?) -> Double {
        if let size, let sizePrice = sizePrices[size] {
            return sizePrice
        }
        return price
    }

    /// What a size costs on top of the Regular pour, e.g. 10 for a Grande Usucha.
    func sizeUpcharge(for size: DrinkSize) -> Double {
        price(for: size) - price(for: .regular)
    }
}

struct CartEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var item: MatchaItem
    var size: DrinkSize?
    var milk: MilkOption?
    var withIceCream: Bool = false
    var quantity: Int

    /// The image that reflects any selected ice cream add-on.
    var imageName: String {
        withIceCream ? (item.iceCreamImageName ?? item.imageName) : item.imageName
    }

    var subtotal: Double {
        let unitPrice = item.price(for: size)
            + (milk?.surcharge ?? 0)
            + (withIceCream ? item.iceCreamAddOnPrice : 0)
        return unitPrice * Double(quantity)
    }
}

extension MatchaItem {
    static var sampleItems: [MatchaItem] {
        [
            // MARK: Drinks
            MatchaItem(id: UUID(), name: "Usucha", category: .drinks,
                       itemDescription: "The matcha equivalent of an Americano — ceremonial-grade matcha whisked with hot water for a light, smooth, and authentic matcha experience.",
                       listDescription: "The matcha equivalent of an Americano, whisked with hot water.",
                       price: 180, sizePrices: [.regular: 180, .grande: 190, .venti: 230],
                       imageName: "usucha", hasSizeOptions: true, hasMilkOptions: false),
            MatchaItem(id: UUID(), name: "Matcha Latte", category: .drinks,
                       itemDescription: "Made with ceremonial-grade matcha and silky milk, our Matcha Latte celebrates the pure character of matcha — smooth, creamy, and thoughtfully made for everyday moments.",
                       listDescription: "Ceremonial-grade matcha with silky milk — smooth and creamy.",
                       price: 235, sizePrices: [.regular: 235, .grande: 275, .venti: 315],
                       imageName: "matcha oat latte", hasSizeOptions: true, hasMilkOptions: true),
            MatchaItem(id: UUID(), name: "Strawberry Matcha Latte", category: .drinks,
                       itemDescription: "Ceremonial-grade matcha layered with ripe strawberries and creamy milk for a refreshing latte with fruity sweetness and earthy depth.",
                       listDescription: "Ceremonial-grade matcha layered with ripe strawberries and creamy milk.",
                       price: 255, sizePrices: [.regular: 255, .grande: 295, .venti: 325],
                       imageName: "strawberry matcha latte", hasSizeOptions: true, hasMilkOptions: true),
            MatchaItem(id: UUID(), name: "Rose Matcha Latte", category: .drinks,
                       itemDescription: "Where vibrant matcha meets the gentle bloom of rose, this smooth and creamy latte blends the subtle sweetness of rose with earthy depth, creating a velvety sip that's both refreshing and serene.",
                       listDescription: "Where vibrant matcha meets the gentle bloom of rose in a velvety latte.",
                       price: 265, sizePrices: [.regular: 265, .grande: 295, .venti: 325],
                       imageName: "rose matcha latte", hasSizeOptions: true, hasMilkOptions: false),
            MatchaItem(id: UUID(), name: "Ube Matcha Latte", category: .drinks,
                       itemDescription: "A dreamy fusion of earthy ceremonial-grade matcha and velvety ube, layered with creamy milk for a beautifully balanced sip that's nutty, subtly sweet, and irresistibly smooth.",
                       listDescription: "A dreamy fusion of earthy matcha and velvety ube, layered with creamy milk.",
                       price: 255, sizePrices: [.regular: 255, .grande: 285, .venti: 305],
                       imageName: "ube matcha latte", hasSizeOptions: true, hasMilkOptions: true),
            MatchaItem(id: UUID(), name: "Einspanner Matcha Latte", category: .drinks,
                       itemDescription: "Earthy matcha beneath a cloud of rich Einspanner cream — a beautifully balanced latte that's creamy, smooth, and effortlessly indulgent.",
                       listDescription: "Earthy matcha beneath a cloud of rich Einspanner cream.",
                       price: 275, sizePrices: [.regular: 275, .grande: 305, .venti: 335],
                       imageName: "einspanner matcha latte", hasSizeOptions: true, hasMilkOptions: false),
            MatchaItem(id: UUID(), name: "Matcha Cloud Tiramisu Latte", category: .drinks,
                       itemDescription: "Bold matcha meets fluffy tiramisu — creamy layers, gentle sweetness, and a cloud of calm in every sip.",
                       listDescription: "Bold matcha meets fluffy tiramisu in creamy, gently sweet layers.",
                       price: 295, sizePrices: [.regular: 295, .grande: 335, .venti: 355],
                       imageName: "matcha cloud tiramisu latte", hasSizeOptions: true, hasMilkOptions: true),
            MatchaItem(id: UUID(), name: "Banana Matcha", category: .drinks,
                       itemDescription: "A comforting blend of ceremonial-grade matcha and ripe banana, finished with creamy milk for a naturally sweet, smooth, and nourishing latte.",
                       listDescription: "A comforting blend of ceremonial-grade matcha and ripe banana.",
                       price: 255, sizePrices: [.regular: 255, .grande: 295, .venti: 325],
                       imageName: "banana matcha", hasSizeOptions: true, hasMilkOptions: true),
            MatchaItem(id: UUID(), name: "Egg Matcha", category: .drinks,
                       itemDescription: "Inspired by Vietnam's beloved egg coffee, this indulgent creation pairs ceremonial-grade matcha with a velvety whipped egg cream, offering a rich, silky texture and a beautifully balanced earthy finish.",
                       listDescription: "Inspired by Vietnam's egg coffee, with velvety whipped egg cream.",
                       price: 235, sizePrices: [.regular: 235, .grande: 275],
                       imageName: "egg matcha", hasSizeOptions: true, hasMilkOptions: false),
            MatchaItem(id: UUID(), name: "London Fog Matcha", category: .drinks,
                       itemDescription: "Ceremonial-grade matcha blended with fragrant Earl Grey tea and creamy milk for a smooth, aromatic latte with delicate bergamot notes.",
                       listDescription: "Ceremonial-grade matcha blended with fragrant Earl Grey tea.",
                       price: 255, sizePrices: [.regular: 255, .grande: 295, .venti: 305],
                       imageName: "london fog matcha", hasSizeOptions: true, hasMilkOptions: false),
            MatchaItem(id: UUID(), name: "Iced Matcha Coco", category: .drinks,
                       itemDescription: "Smooth ceremonial-grade matcha poured over ice and finished with fresh coconut — refreshing, and naturally vibrant.",
                       listDescription: "Smooth matcha poured over ice, finished with fresh coconut.",
                       price: 245, sizePrices: [.regular: 245, .grande: 265, .venti: 295],
                       imageName: "iced matcha coco", hasSizeOptions: true, hasMilkOptions: false),
            MatchaItem(id: UUID(), name: "Coconut Matcha Cloud", category: .drinks,
                       itemDescription: "Ceremonial-grade matcha blended with coconut water and topped with a velvety cloud for a smooth, tropical, and refreshing finish.",
                       listDescription: "Matcha blended with coconut water, topped with a velvety cloud.",
                       price: 255, sizePrices: [.regular: 255, .grande: 275, .venti: 305],
                       imageName: "coconut matcha cloud", hasSizeOptions: true, hasMilkOptions: false),
            MatchaItem(id: UUID(), name: "Cheese Cloud Matcha", category: .drinks,
                       itemDescription: "Made with ceremonial-grade matcha and finished with a velvety cheese cloud, this signature drink brings together earthy depth, creamy richness, and a subtle savory touch in every thoughtfully made cup.",
                       listDescription: "Ceremonial-grade matcha finished with a velvety cheese cloud.",
                       price: 275, sizePrices: [.regular: 275, .grande: 305, .venti: 335],
                       imageName: "cheese cloud matcha", hasSizeOptions: true, hasMilkOptions: true),
            MatchaItem(id: UUID(), name: "Banana Pudding Matcha", category: .drinks,
                       itemDescription: "The rich creaminess of banana pudding paired with vibrant ceremonial-grade matcha creates a dessert-inspired latte that's smooth, mellow, and irresistibly satisfying.",
                       listDescription: "The rich creaminess of banana pudding paired with vibrant matcha.",
                       price: 295, sizePrices: [.regular: 295, .grande: 335, .venti: 355],
                       imageName: "banana pudding matcha", hasSizeOptions: true, hasMilkOptions: false),

            // MARK: Desserts
            MatchaItem(id: UUID(), name: "Matcha Tiramisu", category: .desserts,
                       itemDescription: "Espresso-soaked ladyfingers layered with matcha mascarpone cream.",
                       listDescription: "Espresso-soaked ladyfingers layered with matcha mascarpone cream.",
                       price: 195, imageName: "matcha tiramisu", hasSizeOptions: false, hasMilkOptions: false),
            MatchaItem(id: UUID(), name: "Matcha Brownie", category: .desserts,
                       itemDescription: "Dense, fudgy brownie swirled with ceremonial-grade matcha.",
                       listDescription: "Dense, fudgy brownie swirled with ceremonial-grade matcha.",
                       price: 145, imageName: "matcha brownie", hasSizeOptions: false, hasMilkOptions: false,
                       hasIceCreamOption: true, iceCreamImageName: "matcha brownie with ice cream", iceCreamAddOnPrice: 55),
            MatchaItem(id: UUID(), name: "Matcha Caramel Pudding", category: .desserts,
                       itemDescription: "Silky matcha pudding topped with rich caramel sauce.",
                       listDescription: "Silky matcha pudding topped with rich caramel sauce.",
                       price: 165, imageName: "matcha caramel pudding", hasSizeOptions: false, hasMilkOptions: false,
                       hasIceCreamOption: true, iceCreamImageName: "matcha caramel pudding with ice cream", iceCreamAddOnPrice: 45),
            MatchaItem(id: UUID(), name: "Matcha Basque Cheesecake", category: .desserts,
                       itemDescription: "Burnt Basque-style cheesecake baked with matcha for a bittersweet finish.",
                       listDescription: "Burnt Basque-style cheesecake baked with matcha for a bittersweet finish.",
                       price: 210, imageName: "matcha basque cheesecake", hasSizeOptions: false, hasMilkOptions: false),
            MatchaItem(id: UUID(), name: "Matcha Mille Crepe Cake", category: .desserts,
                       itemDescription: "Dozens of paper-thin matcha crepes layered with fresh cream.",
                       listDescription: "Dozens of paper-thin matcha crepes layered with fresh cream.",
                       price: 225, imageName: "matcha mille crepe cake", hasSizeOptions: false, hasMilkOptions: false),
            MatchaItem(id: UUID(), name: "Matcha Strawberry Daifuku Souffle Pancake", category: .desserts,
                       itemDescription: "Fluffy matcha souffle pancake topped with mochi and a fresh strawberry.",
                       listDescription: "Fluffy souffle pancake with mochi.",
                       price: 235, imageName: "matcha strawberry daifuku souffle pancake", hasSizeOptions: false, hasMilkOptions: false),
            MatchaItem(id: UUID(), name: "Matcha Fresh Cream Swiss Roll", category: .desserts,
                       itemDescription: "Soft matcha sponge rolled with fresh cream and topped with strawberry.",
                       listDescription: "Soft matcha sponge rolled with fresh cream and topped with strawberry.",
                       price: 195, imageName: "matcha fresh cream swiss roll", hasSizeOptions: false, hasMilkOptions: false)
        ]
    }
}
