//
//  LoginView.swift
//  Osacha
//
//  Mobile-number sign in. There is no password: entering a number sends a
//  one-time code, which the next screen verifies.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss

    @State private var number = ""
    @State private var showVerification = false
    @FocusState private var numberFocused: Bool

    private let digitCount = 10

    private var canContinue: Bool {
        number.count == digitCount
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Image("LoginBackground")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                Color.matchaCream.opacity(0.32)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Same logo and height as Home. The extra top padding keeps
                    // it centred where the taller old logo sat.
                    Image("OsachaLogoGreen")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .padding(.top, 59)

                    Spacer(minLength: 24)

                    formCard

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .navigationDestination(isPresented: $showVerification) {
                OTPView()
            }
        }
    }

    private var formCard: some View {
        VStack(spacing: 16) {
            Text("🇵🇭  PHILIPPINES")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.matchaDarkGreen)
                .padding(.horizontal, 22)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(Color.matchaCream.opacity(0.85))
                )
                .overlay(Capsule().stroke(Color.matchaDarkGreen.opacity(0.35), lineWidth: 1.5))

            VStack(spacing: 4) {
                Text("Log in or sign up")
                    .font(.headline)
                    .foregroundStyle(Color.matchaDarkGreen)
                Text("Use your mobile number to log in or register.")
                    .font(.caption)
                    .foregroundStyle(Color.matchaDarkGreen.opacity(0.7))
            }

            HStack(spacing: 12) {
                Text("+63")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.matchaDarkGreen)

                Divider().frame(height: 24)

                TextField("Enter Mobile Number", text: $number)
                    .keyboardType(.numberPad)
                    .focused($numberFocused)
                    .font(.subheadline)
                    .onChange(of: number) { newValue in
                        let digits = newValue.filter(\.isNumber)
                        number = String(digits.prefix(digitCount))
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white))
            .shadow(color: .black.opacity(0.06), radius: 10, y: 3)

            Button {
                session.pendingNumber = number
                numberFocused = false
                showVerification = true
            } label: {
                Text("Next")
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

            Button {
                session.continueAsGuest()
                dismiss()
            } label: {
                Text("Continue as guest")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.matchaGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.matchaCream.opacity(0.92))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.matchaGreen, lineWidth: 1.5)
                    )
            }
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
    LoginView()
        .environmentObject(AppSession())
}
