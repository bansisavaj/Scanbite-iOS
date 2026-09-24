import Foundation

enum DietPreference: String, CaseIterable, Identifiable {
    case none = "No preference"
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"

    var id: String { rawValue }

    /// Whether a product's classified diet type conflicts with this preference.
    /// `.uncertain` never conflicts — there isn't enough information to warn confidently.
    func conflicts(with productDietType: DietType) -> Bool {
        switch self {
        case .none:
            return false
        case .vegetarian:
            return productDietType == .nonVegetarian
        case .vegan:
            return productDietType == .nonVegetarian || productDietType == .vegetarian
        }
    }
}

enum DietPreferenceStore {
    static let storageKey = "diet_preference"

    static var current: DietPreference {
        get {
            guard let raw = UserDefaults.standard.string(forKey: storageKey),
                  let preference = DietPreference(rawValue: raw)
            else { return .none }
            return preference
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: storageKey)
        }
    }
}
