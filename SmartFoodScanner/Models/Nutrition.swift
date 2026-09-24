import Foundation

struct Nutrition: Codable, Hashable {
    var sugarPer100g: Double?
    var fatPer100g: Double?
    var sodiumPer100g: Double?
    var fiberPer100g: Double?
    var proteinPer100g: Double?

    enum Level: String, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case unknown = "Uncertain"
    }

    var sugarLevel: Level {
        guard let sugarPer100g else { return .unknown }
        if sugarPer100g > 22.5 { return .high }
        if sugarPer100g > 5 { return .medium }
        return .low
    }

    var fatLevel: Level {
        guard let fatPer100g else { return .unknown }
        if fatPer100g > 17.5 { return .high }
        if fatPer100g > 3 { return .medium }
        return .low
    }

    var sodiumLevel: Level {
        guard let sodiumPer100g else { return .unknown }
        if sodiumPer100g > 0.6 { return .high }
        if sodiumPer100g > 0.12 { return .medium }
        return .low
    }

    var fiberLevel: Level {
        guard let fiberPer100g else { return .unknown }
        if fiberPer100g >= 6 { return .high }
        if fiberPer100g >= 3 { return .medium }
        return .low
    }
}
