//
//  EditProfileView.swift
//  Osacha
//
//  Name, mobile number and delivery address for the signed-in customer.
//

import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var mobileNumber = ""
    @State private var address = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(Color.matchaGreen)
                        .frame(width: 88, height: 88)
                        .background(Circle().fill(Color.matchaCardCream))
                        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)

                    Button("Change Photo") {}
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.matchaGreen)
                }
                .padding(.top, 12)

                VStack(spacing: 14) {
                    AccountField(label: "Full Name", text: $fullName)
                    AccountField(label: "Mobile Number", text: $mobileNumber)
                    AccountField(label: "Address", text: $address)
                }

                Button {
                    session.profile = UserProfile(fullName: fullName,
                                                  mobileNumber: mobileNumber,
                                                  address: address)
                    session.savePreferences()
                    dismiss()
                } label: {
                    PrimaryButtonLabel(title: "Save Changes")
                }
                .padding(.top, 4)
            }
            .padding()
        }
        .accountBackground()
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fullName = session.profile.fullName
            mobileNumber = session.profile.mobileNumber
            address = session.profile.address
        }
    }
}

#Preview {
    NavigationStack { EditProfileView() }
        .environmentObject(AppSession())
}
