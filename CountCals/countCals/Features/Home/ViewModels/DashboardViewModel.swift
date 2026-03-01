//
//  DashboardViewModel.swift
//  Pace
//

import Foundation
import SwiftData

@Observable
final class DashboardViewModel {
    private(set) var userProfile: UserProfile
    
    init() {
        self.userProfile = UserProfile.load()
    }
    
    var dailyCalories: Int {
        userProfile.dailyCalories
    }
    
    var activityLevel: UserProfile.ActivityLevel {
        userProfile.activityLevel
    }
    
    func consumedCalories(from entries: [FoodEntry]) -> Int {
        todaysEntries(from: entries).reduce(0) { $0 + $1.calories }
    }
    
    func remainingCalories(from entries: [FoodEntry]) -> Int {
        dailyCalories - consumedCalories(from: entries)
    }
    
    func todaysEntries(from entries: [FoodEntry]) -> [FoodEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return entries.filter { calendar.startOfDay(for: $0.timestamp) == today }
    }
    
    /// Entries for a specific date (for Food Log date selector).
    func entries(for date: Date, from entries: [FoodEntry]) -> [FoodEntry] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        return entries.filter { calendar.startOfDay(for: $0.timestamp) == dayStart }
    }
    
    func updateActivityLevel(_ level: UserProfile.ActivityLevel) {
        userProfile.activityLevel = level
        userProfile.dailyCalories = CalorieService.calculateTDEE(
            weight: userProfile.weight,
            height: userProfile.height,
            age: userProfile.age,
            gender: userProfile.gender,
            activityLevel: level
        )
        userProfile.save()
    }

    /// Update full profile; recalculates BMR → TDEE and persists.
    func updateProfile(
        age: Int,
        gender: UserProfile.Gender,
        height: Int,
        weight: Int,
        activityLevel: UserProfile.ActivityLevel
    ) {
        userProfile.age = age
        userProfile.gender = gender
        userProfile.height = height
        userProfile.weight = weight
        userProfile.activityLevel = activityLevel
        userProfile.dailyCalories = CalorieService.calculateTDEE(
            weight: weight,
            height: height,
            age: age,
            gender: gender,
            activityLevel: activityLevel
        )
        userProfile.save()
    }

    // MARK: - Macro Nutrients
    // Based on Mediterranean diet ratio: 45% Carbs, 30% Fat, 25% Protein
    // 1g carbs = 4 kcal, 1g protein = 4 kcal, 1g fat = 9 kcal
    
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
    
    /// Consumed carbs from today's entries
    func consumedCarbs(from entries: [FoodEntry]) -> Int {
        todaysEntries(from: entries).reduce(0) { $0 + $1.carbs }
    }
    
    /// Consumed protein from today's entries
    func consumedProtein(from entries: [FoodEntry]) -> Int {
        todaysEntries(from: entries).reduce(0) { $0 + $1.protein }
    }
    
    /// Consumed fat from today's entries
    func consumedFat(from entries: [FoodEntry]) -> Int {
        todaysEntries(from: entries).reduce(0) { $0 + $1.fat }
    }
    
    /// Remaining carbs based on actual consumption
    func remainingCarbs(from entries: [FoodEntry]) -> Int {
        max(0, dailyCarbs - consumedCarbs(from: entries))
    }
    
    /// Remaining protein based on actual consumption
    func remainingProtein(from entries: [FoodEntry]) -> Int {
        max(0, dailyProtein - consumedProtein(from: entries))
    }
    
    /// Remaining fat based on actual consumption
    func remainingFat(from entries: [FoodEntry]) -> Int {
        max(0, dailyFat - consumedFat(from: entries))
    }
    
    // MARK: - Live Activity
    
    /// Update Live Activity with current nutrition data
    func updateLiveActivity(from entries: [FoodEntry]) {
        LiveActivityService.shared.update(
            remainingCalories: remainingCalories(from: entries),
            remainingCarbs: remainingCarbs(from: entries),
            remainingProtein: remainingProtein(from: entries),
            remainingFat: remainingFat(from: entries)
        )
    }
    
    /// Start Live Activity with current nutrition data
    func startLiveActivity(from entries: [FoodEntry]) {
        LiveActivityService.shared.start(
            dailyTarget: dailyCalories,
            remainingCalories: remainingCalories(from: entries),
            remainingCarbs: remainingCarbs(from: entries),
            remainingProtein: remainingProtein(from: entries),
            remainingFat: remainingFat(from: entries)
        )
    }
}


