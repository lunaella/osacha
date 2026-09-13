//
//  CartView.swift
//  Osacha
//
//  Order summary screen: review cart items, adjust quantities, and place
//  the order.
//

import SwiftUI

struct CartView: View {
    @EnvironmentObject private var controller: OrderController
    @EnvironmentObject private var session: AppSession
    @State private var placedOrder: PastOrder?
    @State private var showConfirmation = false

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
                    }
                    .padding()
                }

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
                            placedOrder = session.recordOrder(itemCount: controller.cartCount,
                                                              total: controller.cartTotal)
                            showConfirmation = true
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
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.matchaSage.ignoresSafeArea())
        .navigationTitle("Your Cart")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.matchaSageDeep, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationDestination(isPresented: $showConfirmation) {
            if let placedOrder {
                OrderConfirmationView(order: placedOrder)
                    .onAppear { controller.clearCart() }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CartView()
    }
    .environmentObject(OrderController())
    .environmentObject(AppSession())
}
