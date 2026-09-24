import Foundation

typealias FoodProduct = Product

struct HealthSummary {
    enum Rating: String, CaseIterable {
        case a = "A"
        case b = "B"
        case c = "C"
        case d = "D"
        case e = "E"
    }

    struct Highlight: Identifiable {
        let id = UUID()
        let title: String
        let value: String
    }

    let rating: Rating
    let verdict: String
    let isLikelyFood: Bool
    let highlights: [Highlight]
    let suggestion: String
    let trustNote: String
    let dietType: DietTypeResult
}
