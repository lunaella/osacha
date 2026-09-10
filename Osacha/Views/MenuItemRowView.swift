//
//  MenuItemRowView.swift
//  Osacha
//
//  Reusable menu-list row: thumbnail, name, description, price, and a
//  favorite toggle.
//

import SwiftUI

struct MenuItemRowView: View {
    let item: MatchaItem

    @EnvironmentObject private var controller: OrderController

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(item.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 72)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.matchaDarkGreen)

                Text(item.itemDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    if item.hasSizeOptions {
                        ForEach(item.availableSizes) { size in
                            Text(size.rawValue.prefix(1))
                                .font(.caption2.bold())
                                .frame(width: 18, height: 18)
                                .background(Circle().fill(Color.matchaSage.opacity(0.25)))
                                .foregroundStyle(Color.matchaDarkGreen)
                        }
                    }
                    Spacer()
                    Text(item.price.asPHP)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.matchaGreen)
                }
            }

            Button {
                controller.toggleFavorite(item)
            } label: {
                Image(systemName: controller.isFavorite(item) ? "heart.fill" : "heart")
                    .foregroundStyle(Color.matchaPinkDeep)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.matchaCardCream))
    }
}

#Preview {
    MenuItemRowView(item: MatchaItem.sampleItems[0])
        .padding()
        .background(Color.matchaSage)
        .environmentObject(OrderController())
}
