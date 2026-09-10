//
//  DeliveryAddressesView.swift
//  Osacha
//
//  Saved delivery addresses, with add and edit flows.
//

import SwiftUI

struct DeliveryAddressesView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(session.addresses) { address in
                    NavigationLink {
                        AddressFormView(mode: .edit(address))
                    } label: {
                        addressCard(address)
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink {
                    AddressFormView(mode: .create)
                } label: {
                    Label("Add New Address", systemImage: "plus")
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
        .navigationTitle("Delivery Addresses")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func addressCard(_ address: SavedAddress) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: address.kind.icon)
                .foregroundStyle(Color.matchaGreen)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 4) {
                Text(address.kind.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.matchaDarkGreen)
                Text(address.oneLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Text("Edit")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.matchaGreen)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.matchaSage.opacity(0.45)))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accountCard()
    }
}

struct AddressFormView: View {
    enum Mode {
        case create
        case edit(SavedAddress)
    }

    let mode: Mode

    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss

    @State private var kind: SavedAddress.Kind = .home
    @State private var street = ""
    @State private var barangay = ""
    @State private var city = ""
    @State private var notes = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Label")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.matchaDarkGreen.opacity(0.7))

                HStack(spacing: 10) {
                    ForEach(SavedAddress.Kind.allCases) { option in
                        OptionPillView(title: option.rawValue, isSelected: kind == option) {
                            kind = option
                        }
                    }
                }

                AccountField(label: "Street Address", placeholder: "123 Rizal Street", text: $street)
                AccountField(label: "Barangay", placeholder: "Brgy. San Isidro", text: $barangay)
                AccountField(label: "City", placeholder: "Quezon City", text: $city)
                AccountField(label: "Delivery Notes (optional)", placeholder: "Gate code, landmark…", text: $notes)

                Button {
                    save()
                    dismiss()
                } label: {
                    PrimaryButtonLabel(title: isEditing ? "Save Changes" : "Save Address")
                }
                .padding(.top, 4)

                if case .edit(let address) = mode {
                    Button(role: .destructive) {
                        session.removeAddress(address)
                        dismiss()
                    } label: {
                        Text("Delete Address")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(.red, lineWidth: 1.5)
                            )
                    }
                }
            }
            .padding()
        }
        .accountBackground()
        .navigationTitle(isEditing ? "Edit Address" : "Add New Address")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: prefill)
    }

    private func prefill() {
        guard case .edit(let address) = mode else { return }
        kind = address.kind
        street = address.street
        barangay = address.barangay
        city = address.city
        notes = address.notes
    }

    private func save() {
        switch mode {
        case .create:
            session.addAddress(SavedAddress(kind: kind, street: street, barangay: barangay,
                                            city: city, notes: notes))
        case .edit(let address):
            var updated = address
            updated.kind = kind
            updated.street = street
            updated.barangay = barangay
            updated.city = city
            updated.notes = notes
            session.update(updated)
        }
    }
}

#Preview {
    NavigationStack { DeliveryAddressesView() }
        .environmentObject(AppSession())
}
