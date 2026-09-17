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
    @State private var showAddPayment = false
    @State private var showCheckout = false

    var body: some View {
        VStack(spacing: 0) {
            if controller.cart.isEmpty {
                Spacer()
                Text("🍵")
                    .font(.system(size: 56))
                Text("Your cart is empty")
                    .font(.headline)
                    .foregroundStyle(Color.matchaDarkGreen)
                    .padding(.top, 8)
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
