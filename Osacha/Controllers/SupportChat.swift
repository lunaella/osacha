//
//  SupportChat.swift
//  Osacha
//
//  The "Chat with us" conversation. A bot answers the common questions and
//  hands the customer over to a person when one is needed. The person is
//  simulated for now: their replies are canned, but the hand-over is real
//  enough to design and test the flow against.
//

import Foundation

struct ChatMessage: Identifiable, Equatable {
    enum Sender: Equatable {
        case customer, bot, agent
        /// A line about the chat itself, such as someone joining.
        case notice
    }

    let id = UUID()
    let sender: Sender
    let text: String
}

@MainActor
final class SupportChat: ObservableObject {
    /// What a customer's message is about.
    enum Intent: CaseIterable {
        case track, delivery, hours, loyalty, payment, menu, change, problem, person, greeting, thanks, unknown

        /// The shortcuts offered under the chat, in the order shown.
        static let quickReplies: [Intent] = [.track, .delivery, .hours, .loyalty, .person]

        /// What the customer says when they tap this shortcut.
        var prompt: String {
            switch self {
            case .track: return "Track my order"
            case .delivery: return "Delivery areas"
            case .hours: return "Opening hours"
            case .loyalty: return "Loyalty stamps"
            default: return "Talk to a person"
            }
        }
    }

    /// The team member the bot hands over to. Not a real person yet.
    static let agentName = "Aya"

    @Published private(set) var messages: [ChatMessage] = []
    /// Someone on the other side is writing a reply.
    @Published private(set) var isTyping = false
    /// The customer has been handed over to a person.
    @Published private(set) var withAgent = false

    /// Misunderstood messages in a row; two and the bot hands over.
    private var misunderstandings = 0
    private var agentReplies = 0
    /// Replies are played out one after another, each after a short pause,
    /// so nothing arrives out of order however fast the customer types.
    private var pending: Task<Void, Never>?

    init() {
        messages = [ChatMessage(sender: .bot, text: localized("Hi! I'm Osacha's chat helper. Ask me about your order, delivery, opening hours, stamps or payment — or ask for a person anytime."))]
    }

    func send(_ text: String) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messages.append(ChatMessage(sender: .customer, text: text))
        respond(to: Self.intent(of: text))
    }

    func ask(_ intent: Intent) {
        messages.append(ChatMessage(sender: .customer, text: localized(intent.prompt)))
        respond(to: intent)
    }

    // MARK: - Replies

    private func respond(to intent: Intent) {
        if withAgent {
            replyAsAgent()
            return
        }

        switch intent {
        case .person, .change, .problem:
            handOver()
        case .unknown:
            misunderstandings += 1
            if misunderstandings >= 2 {
                handOver()
            } else {
                reply(.bot, "Sorry, I didn't quite get that. I can help with orders, delivery, opening hours, stamps and payment — or connect you with a person.")
            }
        default:
            misunderstandings = 0
            reply(.bot, Self.answer(for: intent))
        }
    }

    /// Changes, cancellations and anything that went wrong need someone who
    /// can act on the order, so the bot steps aside for a person.
    private func handOver() {
        reply(.bot, "That's one for our team. I'm connecting you with a person now — hang tight.")
        after(2.0, typing: false) { [weak self] in
            self?.withAgent = true
            self?.messages.append(ChatMessage(sender: .notice,
                                              text: String(format: localized("%@ from the Osacha team joined the chat"), Self.agentName)))
        }
        after(1.4) { [weak self] in
            self?.messages.append(ChatMessage(sender: .agent,
                                              text: String(format: localized("Hi, I'm %@ from Osacha. I've read through your messages — give me a moment to look into this for you."), Self.agentName)))
        }
    }

    private func replyAsAgent() {
        let lines = [
            "Thanks for the details! I'm checking on this now and will update you right here.",
            "Got it — I've noted that down.",
            "I'm still on it. Is there anything else you'd like me to check while I'm here?"
        ]
        let line = lines[min(agentReplies, lines.count - 1)]
        agentReplies += 1
        reply(.agent, line, delay: 1.6)
    }

    private func reply(_ sender: ChatMessage.Sender, _ key: String, delay: Double = 0.9) {
        after(delay) { [weak self] in
            self?.messages.append(ChatMessage(sender: sender, text: localized(key)))
        }
    }

    /// Runs `action` once everything queued before it has played, after
    /// `delay` seconds spent showing the typing dots.
    private func after(_ delay: Double, typing: Bool = true, _ action: @escaping () -> Void) {
        let previous = pending
        pending = Task { [weak self] in
            await previous?.value
            if typing { self?.isTyping = true }
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            self?.isTyping = false
            action()
        }
    }

    // MARK: - Understanding

    private static func answer(for intent: Intent) -> String {
        switch intent {
        case .track: return "You can follow any order under Profile › Order History — tap an order that's still on its way to see its receipt and live status."
        case .delivery: return "We deliver across Quezon City and Makati, with more areas opening soon. You can also pick up at the café."
        case .hours: return "We're open every day from 9AM to 8PM."
        case .loyalty: return "Every order with a drink adds a stamp to your card. Collect 9 and your 10th matcha is on us — see Profile › Loyalty Card."
        case .payment: return "We accept cards, GCash and Maya. Add or change one under Profile › Payment Methods."
        case .menu: return "Our Matcha Cloud Tiramisu Latte is a favourite, and the sakura menu is here for the season. Have a look in Search!"
        case .greeting: return "Hello! What can I help you with today?"
        case .thanks: return "You're welcome! Anything else I can help with?"
        case .change, .problem, .person, .unknown: return ""
        }
    }

    /// Keywords for each intent, checked in this order so the more specific
    /// ones win: "cancel my order" is a change, not tracking. English words
    /// match as the start of a word ("deliver" catches "delivery"); Japanese,
    /// which has no spaces, matches anywhere.
    private static let keywords: [(Intent, [String])] = [
        (.person, ["person", "human", "agent", "staff", "someone", "talk to", "speak to", "manager", "人と", "スタッフ", "オペレーター", "担当"]),
        (.problem, ["refund", "wrong", "missing", "cold", "spill", "damage", "late", "complain", "problem", "issue", "allerg", "返金", "間違", "届かない", "遅い", "問題", "アレルギー", "苦情"]),
        (.change, ["cancel", "change", "edit", "modify", "キャンセル", "変更"]),
        (.delivery, ["deliver", "area", "ship", "配達", "エリア", "届け"]),
        (.hours, ["hour", "open", "close", "営業", "何時", "時間"]),
        (.loyalty, ["stamp", "loyalty", "reward", "point", "free", "スタンプ", "ポイント", "無料"]),
        (.payment, ["pay", "gcash", "maya", "card", "cash", "支払", "カード"]),
        (.menu, ["menu", "recommend", "best", "popular", "drink", "おすすめ", "メニュー", "人気"]),
        (.track, ["track", "where", "status", "order", "追跡", "どこ", "状況", "注文"]),
        (.thanks, ["thank", "thanks", "salamat", "ありがとう"]),
        (.greeting, ["hello", "hi", "hey", "kumusta", "こんにちは", "こんばんは", "おはよう"])
    ]

    static func intent(of text: String) -> Intent {
        let lowered = text.lowercased()
        let words = lowered.split { !$0.isLetter }.map(String.init)
        for (intent, list) in keywords {
            let hit = list.contains { keyword in
                if keyword.allSatisfy({ $0.isASCII && $0.isLetter }) {
                    // Short words must match whole, or "hi" would catch "this".
                    return keyword.count <= 3
                        ? words.contains(keyword)
                        : words.contains { $0.hasPrefix(keyword) }
                }
                return lowered.contains(keyword)
            }
            if hit { return intent }
        }
        return .unknown
    }
}
