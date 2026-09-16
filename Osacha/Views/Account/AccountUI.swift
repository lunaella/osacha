//
//  AccountUI.swift
//  Osacha
//
//  Small shared pieces the account screens are built from, so each screen
//  stays declarative and they all share one look.
//

import SwiftUI

/// Cream page background used across the account section.
struct AccountBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.matchaCream.ignoresSafeArea())
    }
}

/// Rounded card that groups rows or form fields.
struct AccountCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.matchaCardCream)
                    .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
            )
    }
}

extension View {
    func accountBackground() -> some View { modifier(AccountBackground()) }
    func accountCard() -> some View { modifier(AccountCard()) }
}

/// One tappable row: icon, title, optional trailing value, chevron.
struct AccountRow: View {
    let icon: String
    let title: String
    var value: String? = nil
    var isDestructive = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(isDestructive ? Color.red : Color.matchaGreen)
                .frame(width: 26)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isDestructive ? Color.red : Color.matchaDarkGreen)

            Spacer()

            if let value {
                Text(value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}

/// Row with a single-choice check mark, used by Appearance and Language.
struct AccountChoiceRow: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(Color.matchaDarkGreen)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.matchaGreen)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}

/// Labelled text field used by the address, payment and profile forms.
struct AccountField: View {
    let label: String
    var placeholder: String = ""
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.matchaDarkGreen.opacity(0.7))

            TextField(placeholder, text: $text)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white))
        }
    }
}

/// Full-width primary action.
struct PrimaryButtonLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.matchaPinkDeep.opacity(0.95))
            )
            .shadow(color: Color.matchaPinkDeep.opacity(0.3), radius: 16, y: 8)
    }
}

/// Thin divider matching the inset used inside cards.
struct RowDivider: View {
    var body: some View {
        Divider()
            .overlay(Color.matchaDarkGreen.opacity(0.08))
            .padding(.leading, 16)
    }
}

/// The customer's avatar: their chosen photo, or the given fallback mark when
/// they haven't set one.
struct ProfileAvatar<Fallback: View>: View {
    let size: CGFloat
    @ViewBuilder var fallback: () -> Fallback

    @EnvironmentObject private var session: AppSession

    var body: some View {
        Group {
            if let data = session.profilePhoto, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                fallback()
            }
        }
        .frame(width: size, height: size)
        .background(Circle().fill(Color.matchaCardCream))
        .clipShape(Circle())
    }
}
