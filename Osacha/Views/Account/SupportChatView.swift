//
//  SupportChatView.swift
//  Osacha
//
//  "Chat with us": the bot first, then a person once it hands over.
//

import SwiftUI

struct SupportChatView: View {
    @StateObject private var chat = SupportChat()
    @State private var draft = ""
    @FocusState private var isComposing: Bool

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(chat.messages) { message in
                            bubble(message)
                                .id(message.id)
                        }
                        if chat.isTyping {
                            typingBubble
                                .id("typing")
                        }
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: chat.messages.count) { _ in
                    withAnimation { proxy.scrollTo(chat.messages.last?.id, anchor: .bottom) }
                }
                .onChange(of: chat.isTyping) { typing in
                    if typing { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } }
                }
            }

            // Once a person has taken over, the shortcuts would only talk
            // past them.
            if !chat.withAgent {
                quickReplies
            }

            composer
        }
        .accountBackground()
        .navigationTitle("Chat with us")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Pieces

    /// Who the customer is talking to right now.
    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: chat.withAgent ? "person.crop.circle.fill" : "leaf.fill")
                .font(.title3)
                .foregroundStyle(Color.matchaGreen)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.matchaSage.opacity(0.55)))

            VStack(alignment: .leading, spacing: 2) {
                (chat.withAgent ? Text(SupportChat.agentName) : Text("Osacha helper"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.matchaDarkGreen)
                (chat.withAgent ? Text("Osacha team") : Text("Automated answers · a person is a tap away"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.matchaCardCream)
    }

    @ViewBuilder
    private func bubble(_ message: ChatMessage) -> some View {
        switch message.sender {
        case .notice:
            Text(message.text)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.matchaDarkGreen.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity)
        case .customer:
            HStack {
                Spacer(minLength: 48)
                Text(message.text)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.matchaPinkDeep))
            }
        case .bot, .agent:
            HStack(alignment: .bottom, spacing: 8) {
                Image(systemName: message.sender == .agent ? "person.fill" : "leaf.fill")
                    .font(.caption)
                    .foregroundStyle(Color.matchaGreen)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Color.matchaSage.opacity(0.55)))

                VStack(alignment: .leading, spacing: 3) {
                    if message.sender == .agent {
                        Text(SupportChat.agentName)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.matchaGreen)
                    }
                    Text(message.text)
                        .font(.subheadline)
                        .foregroundStyle(Color.matchaDarkGreen)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(message.sender == .agent ? Color.matchaSage.opacity(0.6) : Color.matchaCardCream))

                Spacer(minLength: 48)
            }
        }
    }

    private var typingBubble: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { _ in
                    Circle()
                        .fill(Color.matchaDarkGreen.opacity(0.4))
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.matchaCardCream))
            .padding(.leading, 34)
            .accessibilityLabel("Typing")

            Spacer()
        }
    }

    private var quickReplies: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SupportChat.Intent.quickReplies, id: \.self) { intent in
                    Button {
                        chat.ask(intent)
                    } label: {
                        Text(LocalizedStringKey(intent.prompt))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.matchaGreen)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().stroke(Color.matchaGreen, lineWidth: 1.2))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Type a message…", text: $draft)
                .focused($isComposing)
                .submitLabel(.send)
                .onSubmit(send)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white))

            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(draft.trimmingCharacters(in: .whitespaces).isEmpty
                                     ? Color.matchaGreen.opacity(0.35) : Color.matchaGreen)
            }
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            .accessibilityLabel("Send")
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.matchaCardCream)
    }

    private func send() {
        chat.send(draft)
        draft = ""
    }
}

#Preview {
    NavigationStack { SupportChatView() }
}
