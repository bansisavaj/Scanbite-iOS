import Foundation

struct FoodChatMessage: Identifiable, Equatable {
    enum Sender {
        case user
        case assistant
    }

    let id = UUID()
    let sender: Sender
    let text: String
    let createdAt = Date()
}
