// An order's receipt on a page of its own, opened from Track Order. It
// prints out of the slot as a pink till slip, with the printer heard
// feeding it, every time the page is opened.

import SwiftUI

struct ReceiptView: View {
    let order: PastOrder

    @EnvironmentObject private var session: AppSession

    /// This order as the session has it now, so the printed status is current.
    private var current: PastOrder {
        session.orders.first { $0.id == order.id } ?? order
    }

    var body: some View {
        ScrollView {
            OrderReceipt(order: current, showsProgress: false, style: .thermal)
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 32)
        }
        .background(Color.matchaSage.ignoresSafeArea())
        .toolbarBackground(Color.matchaSageDeep, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationTitle("Receipt")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { ReceiptView(order: PastOrder.samples[0]) }
        .environmentObject(AppSession())
}
