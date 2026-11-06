//
//  Haptics.swift
//  Osacha
//
//  The small taps the phone gives back, so choices and moments feel
//  physical: a tick for picking an option, a pop for a favourite, a buzz of
//  success when an order goes in or a stamp lands.
//

import UIKit

@MainActor
enum Haptics {
    /// A choice changed: a size, a milk, a quantity, a star.
    static func select() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// A light, satisfying tap, like favouriting.
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Something worked: added to cart, order placed, stamp earned.
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Something that undoes, like cancelling an order.
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    /// One line of a receipt feeding out of the printer.
    static func printLine() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.45)
    }

    /// A stamp pressed onto the card.
    static func stamp() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 0.9)
    }
}
