import Foundation

@MainActor
final class AssistantService: ObservableObject {

    private let chatRepository: ChatRepository
    private let householdService: HouseholdService
    private let preferences: AssistantPreferences
    private let contextBuilder: AssistantContextBuilder
    private var client: DeepSeekClient

    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isSending: Bool = false
    @Published var errorMessage: String?

    /// History cap per spec: last 50 messages local.
    private let historyCap = 50

    init(
        chatRepository: ChatRepository,
        householdService: HouseholdService,
        preferences: AssistantPreferences,
        contextBuilder: AssistantContextBuilder
    ) {
        self.chatRepository = chatRepository
        self.householdService = householdService
        self.preferences = preferences
        self.contextBuilder = contextBuilder
        self.client = DeepSeekClient()
    }

    func refresh() async {
        guard let id = householdService.currentHousehold?.id else {
            messages = []
            return
        }
        do {
            messages = try await chatRepository.fetchRecent(householdID: id, limit: historyCap)
        } catch {
            AppLog.data.error("Chat history refresh failed: \(error.localizedDescription, privacy: .public)")
            messages = []
        }
    }

    func clearHistory() async {
        guard let id = householdService.currentHousehold?.id else { return }
        try? await chatRepository.deleteAll(householdID: id)
        messages = []
    }

    /// User just sent a prompt. Persist it, call DeepSeek with the system
    /// prompt + context snapshot + last N messages, persist the reply.
    func send(_ prompt: String) async {
        guard preferences.isConfigured, let householdID = householdService.currentHousehold?.id else {
            errorMessage = AssistantProxyConfig.shared.isConfigured
                ? "Turn on AI assistant in Settings first."
                : "AI assistant isn't available in this build."
            return
        }
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSending = true
        errorMessage = nil
        defer { isSending = false }

        let now = Date()
        let userMessage = ChatMessage(
            id: UUID(),
            householdID: householdID,
            role: .user,
            content: trimmed,
            createdAt: now
        )

        do {
            try await chatRepository.append(userMessage)
            messages.append(userMessage)

            client.model = preferences.model
            let apiMessages = buildAPIMessages(now: now)
            let response = try await client.complete(messages: apiMessages)

            let reply = ChatMessage(
                id: UUID(),
                householdID: householdID,
                role: .assistant,
                content: Self.cleanResponse(response),
                createdAt: Date()
            )
            try await chatRepository.append(reply)
            messages.append(reply)

            try? await chatRepository.trim(householdID: householdID, keepLast: historyCap)
        } catch {
            AppLog.lifecycle.error("Assistant send failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = error.localizedDescription
        }
    }

    private func buildAPIMessages(now: Date) -> [DeepSeekClient.Message] {
        let context = contextBuilder.snapshotJSON(now: now)
        let system = """
        You are the in-app assistant for Splitway, a household expense tracker. \
        You answer questions about the user's household spending using the \
        JSON snapshot below. Be brief, warm, and factual. Never invent numbers. \
        Use the member display names from the snapshot. Today's date is in the \
        snapshot.

        If the question is outside your knowledge (anything not in the snapshot, \
        anything personal beyond household finance, anything that needs real-time \
        data you don't have), politely decline in one sentence and suggest what \
        you CAN answer instead.

        FORMATTING RULES (strict):
        - Plain text only. No markdown. Never use asterisks (*) for bold, italic, \
          or list bullets. If you need a list, use hyphens at line starts.
        - Never use em dashes (—) or en dashes (–). Use commas, periods, "to" for \
          number ranges, or rewrite the sentence.
        - Format dollar amounts like "$12.34".
        - Aim for 1 to 2 sentences. Use a short list of hyphen lines only when you \
          truly are listing multiple items.

        HOUSEHOLD SNAPSHOT:
        \(context)
        """

        var apiMessages: [DeepSeekClient.Message] = [
            DeepSeekClient.Message(role: "system", content: system)
        ]
        // Include the recent chat turns for short-term memory.
        for msg in messages.suffix(12) where msg.role != .system {
            apiMessages.append(DeepSeekClient.Message(role: msg.role.rawValue, content: msg.content))
        }
        return apiMessages
    }

    /// Belt-and-suspenders cleanup for assistant replies. The system prompt
    /// tells DeepSeek not to use asterisks or em/en dashes, but LLMs slip back
    /// into markdown easily. We strip them here so the UI never has to handle
    /// rendering markdown either.
    static func cleanResponse(_ raw: String) -> String {
        var text = raw
        // Strip every asterisk (covers **bold**, *italic*, and bullet asterisks)
        text = text.replacingOccurrences(of: "*", with: "")
        // Em dashes (with or without spaces around them) collapse to a comma
        text = text.replacingOccurrences(of: " — ", with: ", ")
        text = text.replacingOccurrences(of: "—", with: ", ")
        // En dashes between digits become a hyphen (range), elsewhere a comma
        let enDashRange = try? NSRegularExpression(pattern: #"(\d)\s*–\s*(\d)"#)
        if let regex = enDashRange {
            let ns = text as NSString
            text = regex.stringByReplacingMatches(
                in: text,
                range: NSRange(location: 0, length: ns.length),
                withTemplate: "$1-$2"
            )
        }
        text = text.replacingOccurrences(of: " – ", with: ", ")
        text = text.replacingOccurrences(of: "–", with: ",")
        // Collapse any double spaces the substitutions left behind
        while text.contains("  ") {
            text = text.replacingOccurrences(of: "  ", with: " ")
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
