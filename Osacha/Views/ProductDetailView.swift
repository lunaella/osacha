//
//  ProductDetailView.swift
//  Osacha
//
//  Lets the customer customize one menu item (size, milk, quantity) and
//  add it to the cart. The arrows let the customer browse to the other
//  items in the same list (category, search results, or favorites)
//  without leaving the screen.
//

import SwiftUI

private enum OptionPage: Hashable {
    case size
    case milk
}

struct ProductDetailView: View {
    /// The full list this detail screen was opened from, so the arrows can browse it.
    let items: [MatchaItem]

    @State private var currentIndex: Int

    @EnvironmentObject private var controller: OrderController
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSize: DrinkSize = .regular
    @State private var selectedMilk: MilkOption = .regular
    @State private var withIceCream: Bool = false
    @State private var quantity: Int = 1
    @State private var didAddToCart = false

    init(item: MatchaItem, items: [MatchaItem]) {
        self.items = items
        _currentIndex = State(initialValue: items.firstIndex(where: { $0.id == item.id }) ?? 0)
    }

    private var item: MatchaItem { items[currentIndex] }

    private var pages: [OptionPage] {
        var result: [OptionPage] = []
        if item.hasSizeOptions { result.append(.size) }
        if item.hasMilkOptions { result.append(.milk) }
        return result
    }

    /// Height of the fixed hero block, generous enough to fit the longest
    /// item name/description without truncating.
    private let heroHeight: CGFloat = 265
    /// The wavy divider plus its padding, which travel with the sheet.
    private let dividerBlockHeight: CGFloat = 34

    /// The pink panel that travels as one piece. The wavy divider is not part
    /// of it — that stays put with the hero.
    private func sheet(minHeight: CGFloat) -> some View {
        optionsSheet(minHeight: minHeight)
            .background(
                UnevenRoundedRectangle(topLeadingRadius: 32, topTrailingRadius: 32)
                    .fill(Color.matchaPinkPale)
            )
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                // Hero and wavy divider both stay where they are; only the
                // pink panel travels over them.
                VStack(spacing: 0) {
                    heroCarousel

                    WavyDivider()
                        .stroke(Color.matchaPinkDeep, lineWidth: 2.5)
                        .frame(height: 18)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 16)

                    Spacer(minLength: 0)
                }

                ScrollView {
                    VStack(spacing: 0) {
                        // A window onto the hero sitting behind the panel.
                        Color.clear
                            .frame(height: heroHeight + dividerBlockHeight)

                        // Sized to its own content, so the scroll stops as
                        // soon as everything in the panel is on screen rather
                        // than letting it ride all the way up the screen.
                        sheet(minHeight: proxy.size.height - heroHeight - dividerBlockHeight)
                    }
                }
                .scrollIndicators(.hidden)
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
                Button {
                    controller.toggleFavorite(item)
                } label: {
                    Image(systemName: controller.isFavorite(item) ? "heart.fill" : "heart")
                }
            }
        }
        .toolbarBackground(Color.matchaSageDeep, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
    }

    private var displayImageName: String {
        guard withIceCream, let iceCreamImage = item.iceCreamImageName else {
            return item.imageName
        }
        return iceCreamImage
    }

    /// The fixed, self-contained top block: product photo, name, and
    /// description for the current item, browsable by swiping left/right
    /// or tapping the arrows. It never scrolls and is entirely separate
    /// from the pink options sheet below it — only its own content changes
    /// when the current item changes.
    private var heroCarousel: some View {
        ZStack(alignment: .top) {
            productHero
                .id(item.id)
                .transition(.opacity)
                .gesture(
                    DragGesture(minimumDistance: 24)
                        .onEnded { value in
                            if value.translation.width < -40 {
                                goToNext()
                            } else if value.translation.width > 40 {
                                goToPrevious()
                            }
                        }
                )

            if items.count > 1 {
                heroArrows
            }
        }
        .frame(height: heroHeight)
    }

    private var heroArrows: some View {
        HStack {
            Button(action: goToPrevious) {
                Image(systemName: "chevron.left")
                    .frame(width: 44, height: 220)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: goToNext) {
                Image(systemName: "chevron.right")
                    .frame(width: 44, height: 220)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .font(.title3)
        .foregroundStyle(Color.matchaDarkGreen.opacity(0.85))
    }

    private var productHero: some View {
        VStack(spacing: 14) {
            Image(displayImageName)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 150)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 10, y: 6)
                .padding(.horizontal, 8)
                .frame(height: 156)

            Text(item.name)
                .font(.title2.bold())
                .foregroundStyle(Color.matchaDarkGreen)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .fixedSize(horizontal: false, vertical: true)

            Text(item.itemDescription)
                .font(.footnote)
                .foregroundStyle(Color.matchaDarkGreen.opacity(0.75))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 32)
        }
    }

    private func goToPrevious() {
        guard items.count > 1 else { return }
        let newIndex = (currentIndex - 1 + items.count) % items.count
        withAnimation {
            currentIndex = newIndex
        }
        resetSelections(for: items[newIndex])
    }

    private func goToNext() {
        guard items.count > 1 else { return }
        let newIndex = (currentIndex + 1) % items.count
        withAnimation {
            currentIndex = newIndex
        }
        resetSelections(for: items[newIndex])
    }

    private var unitPrice: Double {
        item.price(for: item.hasSizeOptions ? selectedSize : nil)
            + (item.hasMilkOptions ? selectedMilk.surcharge : 0)
            + (item.hasIceCreamOption && withIceCream ? item.iceCreamAddOnPrice : 0)
    }

    private var totalPrice: Double {
        unitPrice * Double(quantity)
    }

    private func resetSelections(for _: MatchaItem) {
        selectedSize = .regular
        selectedMilk = .regular
        withIceCream = false
        quantity = 1
        didAddToCart = false
    }

    /// The pink sheet: size/milk pills, the ice cream toggle, the quantity
    /// stepper, and the Add to Cart button, all as one continuous piece that
    /// scrolls together with the rest of the screen.
    private func optionsSheet(minHeight: CGFloat) -> some View {
        VStack(spacing: 18) {
            // Size and Milk are stacked and both visible, as the design has
            // them. They used to be a paged carousel, which hid the milk
            // options behind a swipe most people never made.
            ForEach(pages, id: \.self) { page in
                optionPageView(for: page)
            }

            if item.hasIceCreamOption {
                iceCreamToggle
            }

            VStack(spacing: 12) {
                Text("Quantity")
                    .font(.headline.bold())
                    .foregroundStyle(Color.matchaDarkGreen)

                HStack(spacing: 22) {
                    Button {
                        quantity += 1
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }

                    Text("\(quantity)")
                        .font(.headline)
                        .frame(minWidth: 20)

                    Button {
                        if quantity > 1 { quantity -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                    }
                }
                .foregroundStyle(Color.matchaGreen)
            }

            // Guests order through the login gate in the shell, so the
            // add-to-cart action only shows once signed in.
            if session.isSignedIn {
                Button {
                    controller.addToCart(
                        item: item,
                        size: item.hasSizeOptions ? selectedSize : nil,
                        milk: item.hasMilkOptions ? selectedMilk : nil,
                        withIceCream: item.hasIceCreamOption ? withIceCream : false,
                        quantity: quantity
                    )
                    didAddToCart = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                    }
                } label: {
                    Text(didAddToCart ? "Added!" : "Add to cart · \(totalPrice.asPHP)")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.matchaPinkDeep))
                }
                .disabled(didAddToCart)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .top)
    }

    private var iceCreamToggle: some View {
        Button {
            withIceCream.toggle()
        } label: {
            HStack {
                Image(systemName: withIceCream ? "checkmark.circle.fill" : "circle")
                Text("With Ice Cream")
                Spacer()
                Text("+\(item.iceCreamAddOnPrice.asPHP)")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(withIceCream ? .white : Color.matchaDarkGreen)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(withIceCream ? Color.matchaGreen : Color.white)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func optionPageView(for page: OptionPage) -> some View {
        VStack(spacing: 12) {
            Text(page == .milk ? "Milk" : "Size")
                .font(.headline.bold())
                .foregroundStyle(Color.matchaDarkGreen)

            switch page {
            case .milk:
                HStack(spacing: 8) {
                    ForEach(MilkOption.allCases) { milk in
                        OptionPillView(title: milk.rawValue,
                                       detail: milk.surcharge > 0 ? "+\(milk.surcharge.asPHP)" : nil,
                                       isSelected: selectedMilk == milk) {
                            selectedMilk = milk
                        }
                    }
                }
            case .size:
                HStack(spacing: 10) {
                    ForEach(item.availableSizes) { size in
                        let upcharge = item.sizeUpcharge(for: size)
                        OptionPillView(title: size.rawValue,
                                       detail: upcharge > 0 ? "+\(upcharge.asPHP)" : nil,
                                       isSelected: selectedSize == size) {
                            selectedSize = size
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(item: MatchaItem.sampleItems[4], items: MatchaItem.sampleItems)
    }
    .environmentObject(OrderController())
    .environmentObject(AppSession())
}
