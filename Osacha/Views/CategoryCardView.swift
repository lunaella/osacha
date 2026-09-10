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
        VStack(alignment: .leading, spacing: 10) {
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
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
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
