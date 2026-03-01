//
//  DailyFoodLogViewModel.swift
//  Pace
//
//  ViewModel for DailyFoodLog feature.
//

import Foundation
import SwiftData

@Observable
final class DailyFoodLogViewModel {
    private(set) var userProfile: UserProfile
    
    init() {
        self.userProfile = UserProfile.load()
    }
    
    // MARK: - Daily Targets
    
    var dailyCalories: Int {
        userProfile.dailyCalories
    }
    
    /// Daily target carbs in grams (45% of calories / 4 kcal per gram)
    var dailyCarbs: Int {
        Int(Double(dailyCalories) * 0.45 / 4.0)
    }
    
    /// Daily target protein in grams (25% of calories / 4 kcal per gram)
    var dailyProtein: Int {
        Int(Double(dailyCalories) * 0.25 / 4.0)
    }
    
    /// Daily target fat in grams (30% of calories / 9 kcal per gram)
    var dailyFat: Int {
        Int(Double(dailyCalories) * 0.30 / 9.0)
    }
    
    // MARK: - Entries
    
    /// Entries for a specific date
    func getEntries(for date: Date, from allEntries: [FoodEntry]) -> [FoodEntry] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        return allEntries.filter { calendar.startOfDay(for: $0.timestamp) == dayStart }
    }
    
    // MARK: - Consumed
    
    func consumedCalories(for date: Date, from entries: [FoodEntry]) -> Int {
        getEntries(for: date, from: entries).reduce(0) { $0 + $1.calories }
    }
    
    func consumedCarbs(for date: Date, from entries: [FoodEntry]) -> Int {
        getEntries(for: date, from: entries).reduce(0) { $0 + $1.carbs }
    }
    
    func consumedProtein(for date: Date, from entries: [FoodEntry]) -> Int {
        getEntries(for: date, from: entries).reduce(0) { $0 + $1.protein }
    }
    
    func consumedFat(for date: Date, from entries: [FoodEntry]) -> Int {
        getEntries(for: date, from: entries).reduce(0) { $0 + $1.fat }
    }
    
    // MARK: - Remaining
    
    func remainingCalories(for date: Date, from entries: [FoodEntry]) -> Int {
        max(0, dailyCalories - consumedCalories(for: date, from: entries))
    }
    
    func remainingCarbs(for date: Date, from entries: [FoodEntry]) -> Int {
        max(0, dailyCarbs - consumedCarbs(for: date, from: entries))
    }
    
    func remainingProtein(for date: Date, from entries: [FoodEntry]) -> Int {
        max(0, dailyProtein - consumedProtein(for: date, from: entries))
    }
    
    func remainingFat(for date: Date, from entries: [FoodEntry]) -> Int {
        max(0, dailyFat - consumedFat(for: date, from: entries))
    }
    
    // MARK: - Progress
    
    func caloriesProgress(for date: Date, from entries: [FoodEntry]) -> Double {
        guard dailyCalories > 0 else { return 0 }
        return min(1.0, Double(consumedCalories(for: date, from: entries)) / Double(dailyCalories))
    }
    
    func proteinProgress(for date: Date, from entries: [FoodEntry]) -> Double {
        guard dailyProtein > 0 else { return 0 }
        return min(1.0, Double(consumedProtein(for: date, from: entries)) / Double(dailyProtein))
    }
    
    func fatProgress(for date: Date, from entries: [FoodEntry]) -> Double {
        guard dailyFat > 0 else { return 0 }
        return min(1.0, Double(consumedFat(for: date, from: entries)) / Double(dailyFat))
    }
    
    func carbsProgress(for date: Date, from entries: [FoodEntry]) -> Double {
        guard dailyCarbs > 0 else { return 0 }
        return min(1.0, Double(consumedCarbs(for: date, from: entries)) / Double(dailyCarbs))
    }
    
    // MARK: - Live Activity
    
    func updateLiveActivity(for date: Date, from entries: [FoodEntry]) {
        LiveActivityService.shared.update(
            remainingCalories: remainingCalories(for: date, from: entries),
            remainingCarbs: remainingCarbs(for: date, from: entries),
            remainingProtein: remainingProtein(for: date, from: entries),
            remainingFat: remainingFat(for: date, from: entries)
        )
    }
    
    func startLiveActivity(for date: Date, from entries: [FoodEntry]) {
        LiveActivityService.shared.start(
            dailyTarget: dailyCalories,
            remainingCalories: remainingCalories(for: date, from: entries),
            remainingCarbs: remainingCarbs(for: date, from: entries),
            remainingProtein: remainingProtein(for: date, from: entries),
            remainingFat: remainingFat(for: date, from: entries)
        )
    }
}
