//
//  CartView.swift
//  Osacha
//
//  Order summary screen: review cart items, adjust quantities, and start
//  placing the order. A customer with no payment method is asked for one
//  first; everyone then reviews their details on the checkout page.
//

import SwiftUI

struct CartView: View {
    @EnvironmentObject private var controller: OrderController
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss
    @State private var showAddPayment = false
    @State private var showCheckout = false

    var body: some View {
        VStack(spacing: 0) {
            if controller.cart.isEmpty {
                Spacer()
                emptyState
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(controller.cart) { entry in
                            CartRowView(entry: entry)
                        }

                        // Sits directly beneath the last item rather than
                        // pinned to the bottom of the screen.
                        summaryPanel
                            .padding(.top, 4)
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.matchaSage.ignoresSafeArea())
        .navigationTitle("Your Cart")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.matchaSageDeep, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationDestination(isPresented: $showCheckout) {
            CheckoutView()
        }
        // Continue to checkout only if a method was actually saved; closing
        // the form without one leaves the customer on the cart.
        .sheet(isPresented: $showAddPayment, onDismiss: {
            if !session.paymentMethods.isEmpty { showCheckout = true }
        }) {
            NavigationStack {
                AddPaymentMethodView(prompt: "Add a payment method to place your order.")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showAddPayment = false }
                                .foregroundStyle(Color.matchaGreen)
                        }
                    }
            }
        }
    }

    /// A cup waiting on a saucer of shadow, and a way back to the menu.
    private var emptyState: some View {
        VStack(spacing: 10) {
            Image("usucha")
                .resizable()
                .scaledToFit()
                .frame(height: 130)
                .background(alignment: .bottom) {
                    Ellipse()
                        .fill(Color.matchaDarkGreen.opacity(0.12))
                        .frame(width: 90, height: 14)
                        .blur(radius: 4)
                        .offset(y: 6)
                }
                .padding(.bottom, 12)

            Text("Your cart is empty")
                .font(.title3.bold())
                .foregroundStyle(Color.matchaDarkGreen)

            Text("Pick a matcha and it'll wait for you here.")
                .font(.subheadline)
                .foregroundStyle(Color.matchaDarkGreen.opacity(0.7))
                .multilineTextAlignment(.center)

            Button {
                dismiss()
            } label: {
                Text("Browse the menu")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.matchaPinkDeep))
            }
            .padding(.top, 10)
        }
        .padding(.horizontal, 32)
    }

    private var summaryPanel: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Total")
                    .font(.headline)
                    .foregroundStyle(Color.matchaDarkGreen)
                Spacer()
                Text(controller.cartTotal.asPHP)
                    .font(.title3.bold())
                    .foregroundStyle(Color.matchaDarkGreen)
            }

            // Guests see the login gate from the shell instead; only
            // signed-in customers can actually place the order.
            if session.isSignedIn {
                Button {
                    if session.paymentMethods.isEmpty {
                        showAddPayment = true
                    } else {
                        showCheckout = true
                    }
                } label: {
                    Text("Place Order")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.matchaPinkDeep))
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color.matchaPinkPale))
    }
}

#Preview {
    NavigationStack {
        CartView()
    }
    .environmentObject(OrderController())
    .environmentObject(AppSession())
}
