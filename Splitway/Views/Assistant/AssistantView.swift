import SwiftUI

/// V1 of the assistant per HANDOFF.md P0/3.3: no free-form input. The chat
/// surface is a curated list of suggested-question chips. Conversation history
/// still renders above. Free-form chat is intentionally cut because:
///   - It bakes API spend cost into every tap from the user.
///   - It generates "the AI hallucinated my balance" support tickets.
///   - Real-world usage data says suggested questions cover ~90% of intent.
struct AssistantView: View {
    @EnvironmentObject private var assistantService: AssistantService
    @EnvironmentObject private var preferences: AssistantPreferences

    /// 10 chips, identity-neutral. No hardcoded member names since the chip
    /// list is shared across all households.
    private let chips: [String] = [
        "How much did I spend this month?",
        "How much have we spent on groceries this month?",
        "Who owes me money right now?",
        "Do I owe anyone money?",
        "What's my biggest expense category?",
        "Are we over budget anywhere?",
        "What recurring bills are coming up?",
        "How does this month compare to last month?",
        "What's our biggest expense this week?",
        "How much have I contributed this month?"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg.ignoresSafeArea()

                if !preferences.isConfigured {
                    notConfigured
                } else {
                    VStack(spacing: 0) {
                        if assistantService.messages.isEmpty {
                            empty
                        } else {
                            chat
                        }
                        chipsBar
                    }
                }
            }
            .navigationTitle("Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !assistantService.messages.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button(role: .destructive) {
                                Task { await assistantService.clearHistory() }
                            } label: {
                                Label("Clear conversation", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .task { await assistantService.refresh() }
        }
    }

    // MARK: - States

    private var notConfigured: some View {
        VStack(spacing: 20) {
            Spacer()
            CapybaraPlaceholder(size: 140)
            VStack(spacing: 8) {
                Text("Ask the assistant")
                    .font(.serifTitle)
                    .foregroundStyle(Color.text1)
                Text("Turn on the AI assistant in Settings to start chatting.")
                    .font(.body)
                    .foregroundStyle(Color.text2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.screenH)
            }
            NavigationLink {
                AssistantSettingsView()
            } label: {
                Text("Open Assistant settings")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color.cta, in: .rect(cornerRadius: Radius.pill))
                    .foregroundStyle(Color.ctaText)
            }
            Spacer()
        }
    }

    private var empty: some View {
        VStack(spacing: 12) {
            Spacer()
            CapybaraPlaceholder(size: 140)
            VStack(spacing: 6) {
                Text("Ask me about your spending")
                    .font(.serifTitle)
                    .foregroundStyle(Color.text1)
                Text("Tap a question below. I see your current month, last month, budgets, balances, and recurring bills.")
                    .font(.cardLabel)
                    .foregroundStyle(Color.text2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.screenH)
            }
            Spacer()
        }
    }

    private var chat: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(assistantService.messages) { msg in
                        messageBubble(msg)
                            .id(msg.id)
                    }
                    if assistantService.isSending {
                        thinkingBubble
                    }
                    if let err = assistantService.errorMessage {
                        Text(err)
                            .font(.cardLabel)
                            .foregroundStyle(Color.warn)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.vertical, 12)
            }
            .onChange(of: assistantService.messages.count) { _, _ in
                if let last = assistantService.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    @ViewBuilder
    private func messageBubble(_ message: ChatMessage) -> some View {
        let isUser = message.role == .user
        HStack(alignment: .top, spacing: 8) {
            if isUser { Spacer(minLength: 40) }
            else {
                assistantAvatar
            }
            Text(message.content)
                .font(.body)
                .foregroundStyle(isUser ? Color.ctaText : Color.text1)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isUser ? Color.cta : Color.surface,
                            in: .rect(cornerRadius: 18))
            if !isUser { Spacer(minLength: 40) }
        }
    }

    /// Capybara mascot face used as the assistant's reply avatar.
    private var assistantAvatar: some View {
        Image("CapybaraFace")
            .resizable()
            .scaledToFill()
            .frame(width: 24, height: 24)
            .background(Color.brandSoft)
            .clipShape(.circle)
            .accessibilityHidden(true)
    }

    private var thinkingBubble: some View {
        HStack(alignment: .top, spacing: 8) {
            assistantAvatar
            HStack(spacing: 4) {
                ProgressView().controlSize(.small)
                Text("Thinking…").font(.cardLabel).foregroundStyle(Color.text2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.surface, in: .rect(cornerRadius: 18))
            Spacer(minLength: 40)
        }
    }

    // MARK: - Chip palette (replaces the old free-form input bar)

    private var chipsBar: some View {
        VStack(spacing: 0) {
            Divider().background(Color.divider)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(chips, id: \.self) { question in
                        chipButton(question)
                    }
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.vertical, 12)
            }
            .frame(maxHeight: assistantService.messages.isEmpty ? 320 : 220)
            .background(Color.bg)
        }
    }

    @ViewBuilder
    private func chipButton(_ question: String) -> some View {
        Button {
            Task { await assistantService.send(question) }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "questionmark.bubble")
                    .font(.cardLabel)
                    .foregroundStyle(Color.brand)
                Text(question)
                    .font(.cardLabel)
                    .foregroundStyle(Color.text1)
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption2)
                    .foregroundStyle(Color.text3)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.surface, in: .rect(cornerRadius: Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card)
                    .stroke(Color.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(assistantService.isSending)
        .opacity(assistantService.isSending ? 0.6 : 1)
    }
}
