//
//  OptionPillView.swift
//  Osacha
//
//  Reusable rounded selection pill used for size and milk options on the
//  product detail screen.
//

import SwiftUI

struct OptionPillView: View {
    let title: String
    /// Upgrade fee shown beneath the title, e.g. "+₱30". Hidden when the option is free.
    var detail: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                if let detail {
                    Text(detail)
                        .font(.caption2.weight(.semibold))
                        .opacity(0.75)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .foregroundStyle(isSelected ? .white : Color.matchaDarkGreen)
            .padding(.horizontal, 8)
            .padding(.vertical, detail == nil ? 10 : 7)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? Color.matchaGreen : Color.white)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        OptionPillView(title: "Oat", isSelected: true) {}
        OptionPillView(title: "Soy", isSelected: false) {}
    }
    .padding()
    .background(Color.matchaPinkPale)
}
