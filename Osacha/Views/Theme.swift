//
//  Theme.swift
//  Osacha
//
//  Shared color palette matching the matcha cafe brand: cream backgrounds,
//  sage-green surfaces, deep green text, and soft pink accents.
//

import SwiftUI

extension Color {
    static let matchaCream = Color(red: 0.99, green: 0.97, blue: 0.93)
    static let matchaCardCream = Color(red: 1.0, green: 0.99, blue: 0.96)
    static let matchaDarkGreen = Color(red: 0.20, green: 0.32, blue: 0.20)
    static let matchaGreen = Color(red: 0.36, green: 0.50, blue: 0.32)
    static let matchaSage = Color(red: 0.8784, green: 0.8863, blue: 0.6706)
    static let matchaSageDeep = Color(red: 0.72, green: 0.73, blue: 0.55)
    static let matchaPink = Color(red: 0.95, green: 0.69, blue: 0.75)
    static let matchaPinkDeep = Color(red: 0.90, green: 0.51, blue: 0.61)
    static let matchaPinkPale = Color(red: 0.98, green: 0.88, blue: 0.90)
}

extension Double {
    /// Formats a peso amount as a whole-number price, e.g. "₱255".
    var asPHP: String {
        "₱\(Int(self.rounded()))"
    }
}
