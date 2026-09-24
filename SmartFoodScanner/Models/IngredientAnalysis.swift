import Foundation

struct IngredientAnalysis {
    struct SafetyTag {
        let isSafe: Bool
        let reason: String
    }

    let rating: HealthSummary.Rating
    let verdict: String
    let isLikelyFood: Bool
    let dietType: DietType
    let kidsFriendly: SafetyTag
    let elderSafe: SafetyTag
    let highlights: [HealthSummary.Highlight]
    let suggestion: String
    let trustNote: String
    let healthRiskLevel: String
}
