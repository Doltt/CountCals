//
//  CalorieService.swift
//  Pace
//

import Foundation

enum CalorieService {
    /// BMR via Mifflin-St Jeor (kcal/day)
    static func calculateBMR(
        weight: Int,
        height: Int,
        age: Int,
        gender: UserProfile.Gender
    ) -> Double {
        let w = Double(weight)
        let h = Double(height)
        let a = Double(age)
        switch gender {
        case .male:
            return 10 * w + 6.25 * h - 5 * a + 5
        case .female:
            return 10 * w + 6.25 * h - 5 * a - 161
        }
    }

    /// TDEE = BMR × activity multiplier (readme: TDEE = BMR × 系数)
    static func calculateTDEE(
        weight: Int,
        height: Int,
        age: Int,
        gender: UserProfile.Gender,
        activityLevel: UserProfile.ActivityLevel
    ) -> Int {
        let bmr = calculateBMR(weight: weight, height: height, age: age, gender: gender)
        return Int(round(bmr * activityLevel.multiplier))
    }
}
