// Saved payment methods. Each one can be removed, and new ones added.

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
                Text(method.displaySubtitle)
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
    /// Shown above the form when it's opened from checkout, to say why it
    /// appeared.
    var prompt: String? = nil

    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss

    @State private var kind: PaymentMethod.Kind = .card
    @State private var cardNumber = ""
    @State private var expiry = ""
    @State private var cvv = ""
    @State private var holder = ""
    @State private var mobileNumber = ""

    /// A card needs enough of its number to show the last four digits and an
    /// expiry; a wallet needs its 10-digit mobile number and account name.
    private var canSave: Bool {
        switch kind {
        case .card:
            return cardNumber.filter(\.isNumber).count >= 4 && Self.isValidExpiry(expiry)
        case .gcash, .maya:
            return mobileNumber.filter(\.isNumber).count == 10 && !holder.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    /// The expiry as typed, with the "/" put in after the month.
    private var expiryText: Binding<String> {
        Binding(
            get: { expiry },
            set: { expiry = Self.formatExpiry($0, previous: expiry) }
        )
    }

    /// Keeps only digits, at most MMYY, and writes them as "MM/YY". The "/"
    /// appears as soon as the month is complete, and deleting it takes the
    /// slash away rather than putting it straight back. A first digit of 2–9
    /// can only be a single-digit month, so it becomes "0X/".
    static func formatExpiry(_ text: String, previous: String) -> String {
        var digits = String(text.filter(\.isNumber).prefix(4))
        let isDeleting = text.count < previous.count

        if digits.count == 1, let first = digits.first, first >= "2", !isDeleting {
            digits = "0" + digits
        }

        switch digits.count {
        case 3...:
            return digits.prefix(2) + "/" + digits.dropFirst(2)
        case 2 where !isDeleting:
            return digits + "/"
        default:
            return digits
        }
    }

    /// A full MM/YY with a real month.
    static func isValidExpiry(_ text: String) -> Bool {
        let digits = text.filter(\.isNumber)
        guard digits.count == 4, let month = Int(digits.prefix(2)) else { return false }
        return (1...12).contains(month)
    }

    private var namePlaceholder: String {
        session.profile.fullName.isEmpty ? (kind == .card ? "Name on card" : "Name on the account") : session.profile.fullName
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let prompt {
                    Text(LocalizedStringKey(prompt))
                        .font(.subheadline)
                        .foregroundStyle(Color.matchaDarkGreen.opacity(0.8))
                        .padding(.bottom, 4)
                }

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

                // Wallets are linked to a mobile number, so they have no
                // expiry or CVV.
                switch kind {
                case .card:
                    AccountField(label: "Card Number", placeholder: "4821 •••• •••• ••••", text: $cardNumber)
                        .keyboardType(.numberPad)

                    HStack(spacing: 12) {
                        AccountField(label: "Expiry", placeholder: "MM/YY", text: expiryText)
                            .keyboardType(.numberPad)
                        AccountField(label: "CVV", placeholder: "•••", text: $cvv)
                            .keyboardType(.numberPad)
                    }

                    AccountField(label: "Cardholder Name", placeholder: namePlaceholder, text: $holder)
                case .gcash, .maya:
                    AccountField(label: "Mobile Number", placeholder: "917 123 4567", text: $mobileNumber)
                        .keyboardType(.numberPad)

                    AccountField(label: "Account Name", placeholder: namePlaceholder, text: $holder)
                }

                Button {
                    let title = kind == .card
                        ? "Visa •••• \(String(cardNumber.filter(\.isNumber).suffix(4)))"
                        : kind.rawValue
                    // Only the last four digits of a wallet's number are shown.
                    let subtitle = kind == .card
                        ? "Expires \(expiry)"
                        : "\(holder) · •••• \(String(mobileNumber.filter(\.isNumber).suffix(4)))"
                    session.addPaymentMethod(PaymentMethod(kind: kind, title: title, subtitle: subtitle))
                    dismiss()
                } label: {
                    PrimaryButtonLabel(title: "Save Payment Method")
                        .opacity(canSave ? 1 : 0.5)
                }
                .disabled(!canSave)
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
