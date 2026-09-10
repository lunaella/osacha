//
//  PaymentMethodsView.swift
//  Osacha
//
//  Saved payment methods. Each one can be removed, and new ones added.
//

import SwiftUI

struct PaymentMethodsView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if session.paymentMethods.isEmpty {
                    Text("No payment methods yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .accountCard()
                } else {
                    ForEach(session.paymentMethods) { method in
                        methodCard(method)
                    }
                }

                NavigationLink {
                    AddPaymentMethodView()
                } label: {
                    Label("Add Payment Method", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.matchaGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.matchaGreen, lineWidth: 1.5)
                        )
                }
            }
            .padding()
        }
        .accountBackground()
        .navigationTitle("Payment Methods")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func methodCard(_ method: PaymentMethod) -> some View {
        HStack(spacing: 12) {
            Image(systemName: method.kind.icon)
                .foregroundStyle(Color.matchaGreen)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(method.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.matchaDarkGreen)
                Text(method.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                withAnimation { session.removePaymentMethod(method) }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.bold())
                    .foregroundStyle(.red)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.red.opacity(0.08)))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .accountCard()
    }
}

struct AddPaymentMethodView: View {
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss

    @State private var kind: PaymentMethod.Kind = .card
    @State private var cardNumber = ""
    @State private var expiry = ""
    @State private var cvv = ""
    @State private var holder = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Method")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.matchaDarkGreen.opacity(0.7))

                HStack(spacing: 10) {
                    ForEach(PaymentMethod.Kind.allCases) { option in
                        OptionPillView(title: option.rawValue, isSelected: kind == option) {
                            kind = option
                        }
                    }
                }

                AccountField(label: "Card Number", placeholder: "4821 •••• •••• ••••", text: $cardNumber)

                HStack(spacing: 12) {
                    AccountField(label: "Expiry", placeholder: "08/27", text: $expiry)
                    AccountField(label: "CVV", placeholder: "•••", text: $cvv)
                }

                AccountField(label: "Cardholder Name", placeholder: "Mikaela Denise Balasoto", text: $holder)

                Button {
                    let title = kind == .card
                        ? "Visa •••• \(String(cardNumber.suffix(4)))"
                        : kind.rawValue
                    let subtitle = kind == .card ? "Expires \(expiry)" : holder
                    session.addPaymentMethod(PaymentMethod(kind: kind, title: title, subtitle: subtitle))
                    dismiss()
                } label: {
                    PrimaryButtonLabel(title: "Save Payment Method")
                }
                .padding(.top, 4)
            }
            .padding()
        }
        .accountBackground()
        .navigationTitle("Add Payment Method")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { PaymentMethodsView() }
        .environmentObject(AppSession())
}
