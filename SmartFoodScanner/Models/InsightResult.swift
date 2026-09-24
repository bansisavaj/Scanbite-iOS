import Foundation

struct InsightResult {
    let quickInsight: String
    let goodPoints: [String]
    let concerns: [String]
    let longTermInsight: String
    let suitability: [String]
    let nutritionSnapshot: [(label: String, level: Nutrition.Level)]
    let reasons: [String]
}
