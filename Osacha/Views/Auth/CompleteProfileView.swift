//
//  CompleteProfileView.swift
//  Osacha
//
//  Shown once, straight after a new number is verified: asks a first-time
//  customer for their name and delivery address before letting them in.
//

import SwiftUI

struct CompleteProfileView: View {
    @EnvironmentObject private var session: AppSession

    @State private var fullName = ""
    @State private var street = ""
    @State private var barangay = ""
    @State private var city = ""

    private var canContinue: Bool {
        [fullName, street, city].allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var body: some View {
        ZStack {
            Image("LoginBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Color.matchaCream.opacity(0.32)
                .ignoresSafeArea()

            ScrollView {
                formCard
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(spacing: 6) {
                Text("Welcome to Osacha!")
                    .font(.title2.bold())
                    .foregroundStyle(Color.matchaDarkGreen)

                Text("Tell us who's ordering and where to deliver.")
                    .font(.caption)
                    .foregroundStyle(Color.matchaDarkGreen.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 4)

            AccountField(label: "Full Name", placeholder: "Juan Dela Cruz", text: $fullName)
                .textContentType(.name)
            AccountField(label: "Street Address", placeholder: "123 Rizal Street", text: $street)
                .textContentType(.streetAddressLine1)
            AccountField(label: "Barangay (optional)", placeholder: "Brgy. San Isidro", text: $barangay)
            AccountField(label: "City", placeholder: "Quezon City", text: $city)
                .textContentType(.addressCity)

            Button {
                let address = SavedAddress(kind: .home,
                                           street: street.trimmingCharacters(in: .whitespaces),
                                           barangay: barangay.trimmingCharacters(in: .whitespaces),
                                           city: city.trimmingCharacters(in: .whitespaces))
                session.completeProfile(fullName: fullName, address: address)
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.matchaPinkDeep.opacity(canContinue ? 0.95 : 0.45))
                    )
            }
            .disabled(!canContinue)
            .shadow(color: Color.matchaPinkDeep.opacity(0.3), radius: 16, y: 8)
            .padding(.top, 6)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.matchaCardCream.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(.white.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.14), radius: 24, y: 10)
        )
    }
}

#Preview {
    NavigationStack {
        CompleteProfileView()
    }
    .environmentObject(AppSession())
}
