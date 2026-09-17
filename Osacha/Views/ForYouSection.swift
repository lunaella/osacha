//
//  ForYouSection.swift
//  Osacha
//
//  Personalized offers, shown at the top of Search when the customer has
//  opted in. Built from their own orders, so it changes as their habits do.
//

import SwiftUI

struct ForYouSection: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var controller: OrderController

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("For you")
                .font(.headline)
                .foregroundStyle(Color.matchaDarkGreen)

            if let offer = session.personalizedOffer(catalog: controller.items) {
                NavigationLink {
                    ProductDetailView(item: offer.item, items: [offer.item])
                } label: {
                    offerRow(image: offer.item.imageName,
                             eyebrow: offer.headline,
                             title: offer.item.name,
                             detail: "Taken off at checkout")
                }
                .buttonStyle(.plain)

                if let suggestion = offer.suggestion {
                    NavigationLink {
                        ProductDetailView(item: suggestion, items: [suggestion])
                    } label: {
                        offerRow(image: suggestion.imageName,
                                 eyebrow: "Loved \(offer.item.name)? Try",
                                 title: suggestion.name,
                                 detail: suggestion.price.asPHP)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("Your offers are on. Place an order and we'll tailor deals to what you like.")
                    .font(.caption)
                    .foregroundStyle(Color.matchaDarkGreen.opacity(0.7))
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.matchaCardCream))
            }
        }
    }

    private func offerRow(image: String, eyebrow: String, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 64)

            VStack(alignment: .leading, spacing: 3) {
                Text(eyebrow)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.matchaPinkDeep)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.matchaDarkGreen)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Color.matchaDarkGreen.opacity(0.6))
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.matchaDarkGreen.opacity(0.4))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.matchaCardCream)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.matchaCardBorder, lineWidth: 1)
        )
    }
}
