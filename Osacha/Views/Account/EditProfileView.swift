//
//  EditProfileView.swift
//  Osacha
//
//  Name, mobile number and delivery address for the signed-in customer.
//

import PhotosUI
import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var mobileNumber = ""
    @State private var address = ""
    @State private var pickedPhoto: PhotosPickerItem?
    @State private var isLoadingPhoto = false
    @State private var photoFailed = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    ProfileAvatar(size: 88) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(Color.matchaGreen)
                    }
                    .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
                    .overlay(alignment: .bottomTrailing) {
                        if isLoadingPhoto {
                            ProgressView()
                                .padding(6)
                                .background(Circle().fill(Color.matchaCardCream))
                        }
                    }

                    PhotosPicker(selection: $pickedPhoto, matching: .images) {
                        Text(session.profilePhoto == nil ? "Add Photo" : "Change Photo")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.matchaGreen)
                    }

                    if session.profilePhoto != nil {
                        Button("Remove Photo") {
                            session.updateProfilePhoto(nil)
                        }
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.matchaDarkGreen.opacity(0.55))
                    }
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
        .onChange(of: pickedPhoto) { item in
            guard let item else { return }
            isLoadingPhoto = true
            Task {
                defer { isLoadingPhoto = false }
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    photoFailed = true
                    return
                }
                session.updateProfilePhoto(image)
            }
        }
        .alert("Couldn't use that photo", isPresented: $photoFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Pick a different image and try again.")
        }
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
