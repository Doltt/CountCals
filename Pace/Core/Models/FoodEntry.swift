//
//  FoodEntry.swift
//  Pace
//

import Foundation
import SwiftData

@Model
final class FoodEntry {
    var id: UUID
    var name: String
    var calories: Int
    var carbs: Int = 0      // grams (default for migration)
    var protein: Int = 0    // grams (default for migration)
    var fat: Int = 0        // grams (default for migration)
    var portion: String
    var timestamp: Date
    
    init(
        name: String,
        calories: Int,
        carbs: Int = 0,
        protein: Int = 0,
        fat: Int = 0,
        portion: String,
        timestamp: Date = .now
    ) {
        self.id = UUID()
        self.name = name
        self.calories = calories
        self.carbs = carbs
        self.protein = protein
        self.fat = fat
        self.portion = portion
        self.timestamp = timestamp
    }
}

// MARK: - Food Emoji Mapping

extension FoodEntry {
    var emoji: String {
        let lowerName = name.lowercased()
        
        // Carbs / Grains
        if lowerName.contains("noodle") || lowerName.contains("ramen") { return "🍜" }
        if lowerName.contains("pasta") || lowerName.contains("spaghetti") { return "🍝" }
        if lowerName.contains("rice") { return "🍚" }
        if lowerName.contains("bread") || lowerName.contains("toast") { return "🍞" }
        if lowerName.contains("sandwich") { return "🥪" }
        if lowerName.contains("burger") { return "🍔" }
        if lowerName.contains("pizza") { return "🍕" }
        if lowerName.contains("oat") || lowerName.contains("cereal") { return "🥣" }
        
        // Proteins
        if lowerName.contains("chicken") || lowerName.contains("turkey") { return "🍗" }
        if lowerName.contains("steak") || lowerName.contains("beef") { return "🥩" }
        if lowerName.contains("egg") { return "🥚" }
        if lowerName.contains("fish") || lowerName.contains("salmon") { return "🐟" }
        
        // Fruits & Veg
        if lowerName.contains("avocado") { return "🥑" }
        if lowerName.contains("salad") { return "🥗" }
        if lowerName.contains("apple") { return "🍎" }
        if lowerName.contains("banana") { return "🍌" }
        if lowerName.contains("orange") { return "🍊" }
        if lowerName.contains("potato") { return "🥔" }
        if lowerName.contains("carrot") { return "🥕" }
        
        // Dairy
        if lowerName.contains("yogurt") { return "🥛" }
        if lowerName.contains("cheese") { return "🧀" }
        if lowerName.contains("milk") { return "🥛" }
        
        // Drinks
        if lowerName.contains("coffee") { return "☕" }
        if lowerName.contains("tea") { return "🍵" }
        
        return "🍽️"
    }
}
