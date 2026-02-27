//
//  UserProfile.swift
//  Pace
//

import Foundation

struct UserProfile: Codable {
    var age: Int
    var gender: Gender
    var height: Int  // cm
    var weight: Int  // kg
    var activityLevel: ActivityLevel
    var dailyCalories: Int
    
    enum Gender: String, Codable, CaseIterable {
        case male
        case female

        var localizedKey: LocalizedKey {
            switch self {
            case .male: return .genderMale
            case .female: return .genderFemale
            }
        }
    }

    enum ActivityLevel: String, Codable, CaseIterable {
        case low
        case medium
        case high

        var localizedKey: LocalizedKey {
            switch self {
            case .low: return .activityLevelLow
            case .medium: return .activityLevelMedium
            case .high: return .activityLevelHigh
            }
        }
        
        var multiplier: Double {
            switch self {
            case .low: return 1.2
            case .medium: return 1.55
            case .high: return 1.9
            }
        }
    }
    
    static let `default` = UserProfile(
        age: 25,
        gender: .male,
        height: 170,
        weight: 70,
        activityLevel: .low,
        dailyCalories: CalorieService.calculateTDEE(
            weight: 70,
            height: 170,
            age: 25,
            gender: .male,
            activityLevel: .low
        )
    )
}

// MARK: - UserDefaults Persistence

extension UserProfile {
    private static let storageKey = "userProfile"
    
    static func load() -> UserProfile {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return .default
        }
        return profile
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
