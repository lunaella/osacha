//
//  CategoryCardView.swift
//  Osacha
//
//  Reusable grid tile representing one menu category on the home screen.
//

import SwiftUI

struct CategoryCardView: View {
    let category: MatchaCategory

    /// How far the product image rises above the card's top edge.
    private let imageLift: CGFloat = 38

    var body: some View {
        VStack(spacing: 10) {
            // Reserves the part of the image that sits inside the card; the
            // image itself is an overlay so it can break the top edge.
            Color.clear
                .frame(height: 120 - imageLift)

            Text(category.rawValue)
                .font(.headline)
                .foregroundStyle(Color.matchaDarkGreen)

            Text(category.subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            // Pushes the text block to the top so both cards, which the grid
            // stretches to a shared height, keep their copy aligned.
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.matchaCardCream)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        )
        // strokeBorder keeps the 1pt line inside the shape, matching the
        // inside-aligned stroke on the card in the design.
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.matchaCardBorder, lineWidth: 1)
        )
        // Drawn over the card rather than inside it, so the product stands
        // proud of the container instead of being boxed in by it.
        .overlay(alignment: .top) {
            Image(category.previewImageName)
                .resizable()
                .scaledToFit()
                .frame(height: 120)
                .shadow(color: .black.opacity(0.18), radius: 8, y: 5)
                .offset(y: -imageLift)
        }
    }
}

#Preview {
    CategoryCardView(category: .drinks)
        .padding()
        .background(Color.matchaCream)
}
