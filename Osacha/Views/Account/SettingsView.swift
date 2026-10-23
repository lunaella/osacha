//
//  SettingsView.swift
//  Osacha
//
//  App settings, plus the entry point to editing the profile and signing out.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var session: AppSession
    @State private var confirmSignOut = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                NavigationLink { EditProfileView() } label: {
                    AccountRow(icon: "person.crop.circle", title: "Edit Profile")
                }
                RowDivider()

                NavigationLink { LanguageView() } label: {
                    AccountRow(icon: "globe", title: "Language", value: session.language.rawValue)
                }
                RowDivider()

                NavigationLink { PrivacyView() } label: {
                    AccountRow(icon: "lock.fill", title: "Privacy")
                }
                RowDivider()

                NavigationLink { HelpSupportView() } label: {
                    AccountRow(icon: "questionmark.circle.fill", title: "Help & Support")
                }
                RowDivider()

                Button {
                    confirmSignOut = true
                } label: {
                    AccountRow(icon: "rectangle.portrait.and.arrow.right",
                               title: "Log Out", isDestructive: true)
                }
            }
            .buttonStyle(.plain)
            .accountCard()
            .padding()
        }
        .accountBackground()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Log out?", isPresented: $confirmSignOut) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) { session.signOut() }
        } message: {
            Text("You'll need to sign in again to place orders.")
        }
    }
}

struct LanguageView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        ScrollView {
            Text("App language. Menu items keep their original names.")
                .font(.caption)
                .foregroundStyle(Color.matchaDarkGreen.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 12)

            VStack(spacing: 0) {
                ForEach(Array(AppLanguage.allCases.enumerated()), id: \.element.id) { index, language in
                    Button {
                        session.language = language
                        session.savePreferences()
                    } label: {
                        AccountChoiceRow(title: language.rawValue, isSelected: session.language == language)
                    }
                    if index < AppLanguage.allCases.count - 1 { RowDivider() }
                }
            }
            .buttonStyle(.plain)
            .accountCard()
            .padding()
        }
        .accountBackground()
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyView: View {
    @EnvironmentObject private var session: AppSession

    /// Tracking a rider needs location, so switching tracking on while
    /// location is off asks first.
    @State private var askForLocation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                toggleRow("Location Services", caption: "Find your address and track your rider",
                          isOn: Binding(get: { session.locationServices },
                                        set: { session.setLocationServices($0) }))
                RowDivider()
                toggleRow("Order Tracking", caption: "Live updates as your order moves along",
                          isOn: Binding(get: { session.orderTracking },
                                        set: { on in
                                            if on && !session.locationServices {
                                                askForLocation = true
                                            } else {
                                                session.orderTracking = on
                                                session.savePreferences()
                                            }
                                        }))
                RowDivider()
                toggleRow("Personalized Offers", caption: "Deals based on what you order",
                          isOn: Binding(get: { session.personalizedOffers },
                                        set: { session.personalizedOffers = $0; session.savePreferences() }))
                RowDivider()
                toggleRow("Share Analytics", caption: "Anonymous usage data to help improve Osacha",
                          isOn: Binding(get: { session.shareAnalytics },
                                        set: { session.shareAnalytics = $0; session.savePreferences() }))
            }
            .accountCard()
            .padding(.horizontal)
            .padding(.top)

            VStack(spacing: 0) {
                AccountRow(icon: "square.and.arrow.down", title: "Download My Data")
                RowDivider()
                AccountRow(icon: "trash", title: "Delete Account", isDestructive: true)
            }
            .accountCard()
            .padding()
        }
        .accountBackground()
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Turn on Location Services?", isPresented: $askForLocation) {
            Button("Not Now", role: .cancel) {}
            Button("Turn On") {
                session.setLocationServices(true)
                session.orderTracking = true
                session.savePreferences()
            }
        } message: {
            Text("Order Tracking uses your location to show where your rider is on the way.")
        }
    }

    private func toggleRow(_ title: LocalizedStringKey, caption: LocalizedStringKey, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.matchaDarkGreen)
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(Color.matchaDarkGreen.opacity(0.6))
            }
        }
        .tint(Color.matchaGreen)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct HelpSupportView: View {
    /// Where support email goes, and the store's line. The number is a
    /// placeholder until the café has a real one.
    static let supportEmail = "osacha@business.co"
    static let storePhone = "+63 2 8123 4567"

    @Environment(\.openURL) private var openURL
    /// Set when the phone has no app for the link, e.g. Mail or calls on a
    /// simulator or an iPad, so the address or number can be shown instead.
    @State private var unreachable: Contact?

    private enum Contact: Identifiable {
        case email, phone
        var id: Self { self }
    }

    private let faqs: [(String, String)] = [
        ("How do I track my order?", "Open Profile › Order History and tap any active order to see its live status and pickup time."),
        ("Can I change my order?", "You can edit or cancel within 2 minutes of placing it — before the barista starts preparing."),
        ("What is the refund policy?", "Full refund if an order is wrong or undelivered. Reach out within 24 hours via Chat."),
        ("Where do you deliver?", "We deliver across Quezon City and Makati, with more areas opening soon.")
    ]

    var body: some View {
        ScrollView {
            Text("FAQ")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.matchaDarkGreen.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 12)

            VStack(spacing: 0) {
                ForEach(Array(faqs.enumerated()), id: \.offset) { index, faq in
                    DisclosureGroup {
                        Text(LocalizedStringKey(faq.1))
                            .font(.caption)
                            .foregroundStyle(Color.matchaDarkGreen.opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 12)
                    } label: {
                        Text(LocalizedStringKey(faq.0))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.matchaDarkGreen)
                            .padding(.vertical, 14)
                    }
                    .tint(Color.matchaDarkGreen.opacity(0.5))
                    .padding(.horizontal, 16)

                    if index < faqs.count - 1 { RowDivider() }
                }
            }
            .accountCard()
            .padding(.horizontal)

            Text("CONTACT US")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.matchaDarkGreen.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 24)

            VStack(spacing: 0) {
                NavigationLink { SupportChatView() } label: {
                    AccountRow(icon: "bubble.left.and.bubble.right.fill", title: "Chat with us", value: "24/7")
                }
                RowDivider()
                Button { open(.email) } label: {
                    AccountRow(icon: "envelope.fill", title: "Email support", value: "1–2 days")
                }
                RowDivider()
                Button { open(.phone) } label: {
                    AccountRow(icon: "phone.fill", title: "Call the store", value: "9AM–8PM")
                }
            }
            .buttonStyle(.plain)
            .accountCard()
            .padding()
        }
        .accountBackground()
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $unreachable) { contact in
            switch contact {
            case .email:
                return Alert(title: Text("Couldn't open Mail"),
                             message: Text("Email us at \(Self.supportEmail)"))
            case .phone:
                return Alert(title: Text("Couldn't start a call"),
                             message: Text("Call us at \(Self.storePhone)"))
            }
        }
    }

    /// Opens a new email to support, or the phone app with the store's
    /// number filled in, ready to call.
    private func open(_ contact: Contact) {
        let link: String
        switch contact {
        case .email:
            link = "mailto:\(Self.supportEmail)?subject=\(localized("Osacha support").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        case .phone:
            link = "tel:" + Self.storePhone.filter { $0.isNumber || $0 == "+" }
        }
        guard let url = URL(string: link) else { return }
        openURL(url) { accepted in
            if !accepted { unreachable = contact }
        }
    }
}

#Preview {
    NavigationStack { SettingsView() }
        .environmentObject(AppSession())
}
