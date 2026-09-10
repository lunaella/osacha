//
//  CartRowView.swift
//  Osacha
//
//  Reusable cart-list row: item summary, size/milk config, quantity
//  stepper, and a remove button.
//

import SwiftUI

struct CartRowView: View {
    let entry: CartEntry

    @EnvironmentObject private var controller: OrderController

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(entry.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 68)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.item.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.matchaDarkGreen)

                let configParts = [entry.size?.rawValue, entry.milk?.rawValue,
                                    entry.withIceCream ? "With Ice Cream" : nil]
                    .compactMap { $0 }
                if !configParts.isEmpty {
                    Text(configParts.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(entry.subtotal.asPHP)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.matchaGreen)
            }

            Spacer()

            HStack(spacing: 10) {
                Button {
                    controller.updateQuantity(for: entry, quantity: entry.quantity - 1)
                } label: {
                    Image(systemName: "minus.circle.fill")
                }
                Text("\(entry.quantity)")
                    .font(.subheadline.bold())
                    .frame(minWidth: 16)
                Button {
                    controller.updateQuantity(for: entry, quantity: entry.quantity + 1)
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
            .foregroundStyle(Color.matchaGreen)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.matchaCardCream))
    }
}

#Preview {
    let controller = OrderController()
    let entry = CartEntry(id: UUID(), item: MatchaItem.sampleItems[4], size: .grande, milk: .oat, quantity: 2)
    return CartRowView(entry: entry)
        .padding()
        .background(Color.matchaSage)
        .environmentObject(controller)
}
