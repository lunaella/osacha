//
//  RateOrderView.swift
//  Osacha
//
//  Asks how a finished order was: stars, a few quick picks, and an optional
//  comment. Shown as a sheet from the home screen prompt, the order history
//  and the tracking screen.
//

import SwiftUI

struct RateOrderView: View {
    let order: PastOrder

    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss

    @State private var stars = 0
    @State private var tags: Set<String> = []
    @State private var comment = ""

    /// Quick picks, praise first. Which set shows depends on the stars, so a
    /// low rating can say what went wrong without typing.
    private static let praise = ["Tasty", "Fast", "Well packed", "Friendly staff", "Good value"]
    private static let problems = ["Too sweet", "Not sweet enough", "Took too long", "Spilled", "Wrong item"]

    private var choices: [String] { stars >= 4 ? Self.praise : Self.problems }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 6) {
                        Text("How was your order?")
                            .font(.title2.bold())
                        Text("Order #\(order.reference) · \(order.placedAtText)")
                            .font(.subheadline)
                            .opacity(0.7)
                        if let names = order.lines?.map(\.name), !names.isEmpty {
                            Text(names.joined(separator: ", "))
                                .font(.caption)
                                .opacity(0.7)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .foregroundStyle(Color.matchaDarkGreen)
                    .padding(.top, 12)

                    starPicker

                    if stars > 0 {
                        tagPicker
                            .transition(.opacity)

                        TextField("Tell us more (optional)", text: $comment, axis: .vertical)
                            .lineLimit(3...6)
                            .font(.subheadline)
                            .padding(16)
                            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.matchaCardCream))
                            .transition(.opacity)
                    }

                    Button {
                        session.rate(order, stars: stars, tags: tags.sorted(), comment: comment)
                        dismiss()
                    } label: {
                        PrimaryButtonLabel(title: "Submit rating")
                    }
                    .disabled(stars == 0)
                    .opacity(stars == 0 ? 0.45 : 1)
                }
                .padding()
                .animation(.easeInOut(duration: 0.2), value: stars)
            }
            .accountBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not Now") {
                        session.skipRating(order)
                        dismiss()
                    }
                    .foregroundStyle(Color.matchaGreen)
                }
            }
        }
        .presentationDetents([.large])
    }

    private var starPicker: some View {
        HStack(spacing: 10) {
            ForEach(1...5, id: \.self) { value in
                Button {
                    // Switching between praise and problems clears picks that
                    // no longer apply.
                    if (value >= 4) != (stars >= 4) { tags.removeAll() }
                    stars = value
                } label: {
                    Image(systemName: value <= stars ? "star.fill" : "star")
                        .font(.system(size: 34))
                        .foregroundStyle(value <= stars ? Color.matchaPinkDeep : Color.matchaDarkGreen.opacity(0.3))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("\(value) stars"))
            }
        }
    }

    private var tagPicker: some View {
        // Two rows that wrap by hand; a flowing layout needs iOS 16's Layout
        // protocol, which is more than five chips call for.
        VStack(spacing: 8) {
            ForEach([Array(choices.prefix(3)), Array(choices.dropFirst(3))], id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { tag in
                        let selected = tags.contains(tag)
                        Button {
                            if selected { tags.remove(tag) } else { tags.insert(tag) }
                        } label: {
                            Text(LocalizedStringKey(tag))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(selected ? .white : Color.matchaGreen)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(selected ? Color.matchaGreen : Color.clear))
                                .overlay(Capsule().stroke(Color.matchaGreen, lineWidth: 1.2))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

/// A compact prompt for the latest unrated order, opening the rating sheet.
struct RateOrderPrompt: View {
    let order: PastOrder
    @State private var showRating = false

    var body: some View {
        Button {
            showRating = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "star.bubble.fill")
                    .font(.title3)
                    .foregroundStyle(Color.matchaPinkDeep)
                VStack(alignment: .leading, spacing: 3) {
                    Text("How was order #\(order.reference)?")
                        .font(.subheadline.weight(.semibold))
                    HStack(spacing: 3) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(Color.matchaPinkDeep)
                }
                .foregroundStyle(Color.matchaDarkGreen)
                Spacer()
                Text("Rate")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.matchaPinkDeep))
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.matchaCardCream))
            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showRating) {
            RateOrderView(order: order)
        }
    }
}
