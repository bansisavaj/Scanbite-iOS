import Foundation

enum DietType: String, Codable, Hashable {
    case vegan = "Vegan"
    case vegetarian = "Vegetarian"
    case nonVegetarian = "Non-Vegetarian"
    case uncertain = "Uncertain"
}

struct DietTypeResult: Hashable {
    let type: DietType
    let explanation: String
    let matchedIngredients: [String]
}
