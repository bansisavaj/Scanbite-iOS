import Foundation

@MainActor
final class FoodChatViewModel: ObservableObject {
    @Published var messages: [FoodChatMessage] = [
        FoodChatMessage(
            sender: .assistant,
            text: "Hi foodie. What did you eat today, or what label are we decoding? Ask me about sugar, sodium, maida, protein, kids, elders, or vegan checks."
        )
    ]
    @Published var draft = ""
    @Published var isThinking = false
    @Published private(set) var visibleSuggestions = [
        "Is high sugar okay?",
        "What is maida?",
        "Is this good for elders?"
    ]

    private let allSuggestions = [
        "Is high sugar okay?",
        "What is maida?",
        "Is this good for elders?",
        "Decode this snack for me",
        "Is this okay for kids?",
        "What makes food ultra-processed?",
        "Is whey vegan?",
        "What should I check first?",
        "Is sodium really a big deal?"
    ]

    private let chatService = FoodChatService()
    private var suggestionOffset = 0

    func send() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty == false, isThinking == false else { return }

        messages.append(FoodChatMessage(sender: .user, text: text))
        AppAnalyticsService.shared.log(.foodChatQuestionAsked)
        draft = ""
        isThinking = true
        rotateSuggestions()

        try? await Task.sleep(nanoseconds: 650_000_000)

        let recentReplies = messages
            .suffix(6)
            .filter { $0.sender == .assistant }
            .map(\.text)
        let reply = chatService.answer(
            to: text,
            turn: messages.count,
            recentReplies: Array(recentReplies)
        )
        messages.append(FoodChatMessage(sender: .assistant, text: reply))
        isThinking = false
    }

    func sendSuggestion(_ suggestion: String) async {
        draft = suggestion
        await send()
    }

    private func rotateSuggestions() {
        suggestionOffset = (suggestionOffset + 3) % allSuggestions.count
        visibleSuggestions = (0..<3).map { index in
            allSuggestions[(suggestionOffset + index) % allSuggestions.count]
        }
    }
}
