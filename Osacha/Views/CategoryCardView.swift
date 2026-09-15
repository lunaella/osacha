//
//  CategoryCardView.swift
//  Osacha
//
//  Reusable grid tile representing one menu category on the home screen.
//

import SwiftUI

struct CategoryCardView: View {
    let category: MatchaCategory

    var body: some View {
        VStack(spacing: 10) {
            Image(category.previewImageName)
                .resizable()
                .scaledToFill()
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

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
    }
}

#Preview {
    CategoryCardView(category: .drinks)
        .padding()
        .background(Color.matchaCream)
}
