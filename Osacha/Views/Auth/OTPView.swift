//
//  OTPView.swift
//  Osacha
//
//  Six-digit verification step. A single hidden field backs the six boxes so
//  the keyboard behaves normally while the boxes stay purely presentational.
//

import SwiftUI

struct OTPView: View {
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss

    @State private var code = ""
    /// Set when the verified number is new, so its name and address are asked for.
    @State private var showProfileSetup = false
    @FocusState private var codeFocused: Bool

    private let digitCount = 6

    private var maskedNumber: String {
        session.pendingNumber.isEmpty ? session.profile.mobileNumber : "+63 " + session.pendingNumber
    }

    var body: some View {
        ZStack {
            Image("LoginBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Color.matchaCream.opacity(0.32)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text("Verification Code")
                    .font(.title2.bold())
                    .foregroundStyle(Color.matchaDarkGreen)

                Text("We sent a 6-digit code to \(maskedNumber)")
                    .font(.caption)
                    .foregroundStyle(Color.matchaDarkGreen.opacity(0.7))
                    .multilineTextAlignment(.center)

                digitBoxes
                    .padding(.top, 6)

                VStack(spacing: 2) {
                    Text("Didn't get the code?")
                        .font(.caption)
                        .foregroundStyle(Color.matchaDarkGreen.opacity(0.6))
                    Button("Resend Code") { code = "" }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.matchaGreen)
                }

                Button {
                    showProfileSetup = session.verifyCode()
                } label: {
                    Text("Verify")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.matchaPinkDeep.opacity(code.count == digitCount ? 0.95 : 0.45))
                        )
                }
                .disabled(code.count != digitCount)
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
            .padding(.horizontal, 20)
        }
        .navigationBarBackButtonHidden(false)
        .navigationDestination(isPresented: $showProfileSetup) {
            CompleteProfileView()
        }
        .onAppear { codeFocused = true }
    }

    private var digitBoxes: some View {
        ZStack {
            // Hidden field drives the keyboard; the boxes below mirror it.
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .focused($codeFocused)
                .opacity(0.01)
                .onChange(of: code) { newValue in
                    let digits = newValue.filter(\.isNumber)
                    code = String(digits.prefix(digitCount))
                }

            HStack(spacing: 10) {
                ForEach(0..<digitCount, id: \.self) { index in
                    let characters = Array(code)
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.white.opacity(0.92))
                        .frame(width: 48, height: 58)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(index < characters.count ? Color.matchaGreen : .clear, lineWidth: 1.5)
                        )
                        .overlay(
                            Text(index < characters.count ? String(characters[index]) : "")
                                .font(.title3.bold())
                                .foregroundStyle(Color.matchaDarkGreen)
                        )
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { codeFocused = true }
        }
    }
}

#Preview {
    NavigationStack {
        OTPView()
    }
    .environmentObject(AppSession())
}
