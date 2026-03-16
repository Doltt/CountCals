//
//  DashboardBarsView.swift
//  Pace
//
//  Food icon bar chart with fill animation.
//

import SwiftUI

struct DashboardBarsView: View {
    let consumedCalories: Int
    let totalCalories: Int
    let consumedProtein: Int
    let totalProtein: Int
    let consumedCarbs: Int
    let totalCarbs: Int
    let consumedFat: Int
    let totalFat: Int
    let activityLevel: UserProfile.ActivityLevel
    let onActivityLevelTap: () -> Void
    
    private var settings: AppSettingsManager { AppSettingsManager.shared }
    
    private var calorieProgress: Double {
        totalCalories > 0 ? min(1.0, Double(consumedCalories) / Double(totalCalories)) : 0
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // Calorie + Activity Level Combined Card
            CalorieWithActivityLevel(
                consumed: consumedCalories,
                total: totalCalories,
                progress: calorieProgress,
                activityLevel: activityLevel,
                onActivityLevelTap: onActivityLevelTap
            )
            
            // Three Food Bars
            HStack(alignment: .bottom, spacing: 40) {
                // Bar 1: Protein - Salmon
                FoodBar(
                    value: consumedProtein,
                    total: totalProtein,
                    label: settings.localized(.protein),
                    imageName: "salmon",
                    height: 260
                )
                
                // Bar 2: Carbs - Baguette
                FoodBar(
                    value: consumedCarbs,
                    total: totalCarbs,
                    label: settings.localized(.carbs),
                    imageName: "baguette",
                    height: 260
                )
                
                // Bar 3: Fat - Butter
                FoodBar(
                    value: consumedFat,
                    total: totalFat,
                    label: settings.localized(.fat),
                    imageName: "butter",
                    height: 260
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(settings.localized(.accCaloriesProgress)): \(consumedCalories) \(settings.localized(.consumed)), \(totalCalories) \(settings.localized(.calories)). \(settings.localized(.protein)): \(consumedProtein)g / \(totalProtein)g. \(settings.localized(.carbs)): \(consumedCarbs)g / \(totalCarbs)g. \(settings.localized(.fat)): \(consumedFat)g / \(totalFat)g")
    }
}

// MARK: - Calorie + Activity Level Combined

struct CalorieWithActivityLevel: View {
    let consumed: Int
    let total: Int
    let progress: Double
    let activityLevel: UserProfile.ActivityLevel
    let onActivityLevelTap: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private var settings: AppSettingsManager { AppSettingsManager.shared }
    
    var body: some View {
        Button {
            onActivityLevelTap()
        } label: {
            VStack(spacing: 8) {
                // Large calorie number with cal unit
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(consumed)")
                        .font(.paceRounded(size: 44, weight: .bold))
                        .foregroundColor(Color(.label))
                    
                    Text("/\(total) cal")
                        .font(.paceRounded(size: 16, weight: .medium))
                        .foregroundColor(Color(.tertiaryLabel))
                }
                
                // Thin progress bar (centered)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.orange.opacity(0.15))
                            .frame(height: 4)
                        
                        Capsule()
                            .fill(Color.orange)
                            .frame(width: geo.size.width * progress, height: 4)
                            .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.75), value: progress)
                    }
                }
                .frame(width: 120, height: 4)
                
                // Activity Level
                HStack(spacing: 4) {
                    Text(settings.localized(.activityLevel) + ":")
                        .font(.paceRounded(size: 14, weight: .medium))
                        .foregroundColor(Color(.tertiaryLabel))
                    
                    Text(settings.localized(activityLevel.localizedKey))
                        .font(.paceRounded(size: 14, weight: .semibold))
                        .foregroundColor(Color(.secondaryLabel))
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .padding(.top, 4)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(consumed) \(settings.localized(.caloriesConsumed)), \(total) \(settings.localized(.calories)). \(settings.localized(.activityLevel)): \(settings.localized(activityLevel.localizedKey))")
        .accessibilityHint(settings.localized(.accChangeActivityLevel))
    }
}

// MARK: - Food Bar

struct FoodBar: View {
    let value: Int
    let total: Int
    let label: String
    let imageName: String
    let height: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private var settings: AppSettingsManager { AppSettingsManager.shared }
    
    private var progress: Double {
        total > 0 ? min(1.0, Double(value) / Double(total)) : 0
    }
    
    private var percentageText: String {
        "\(Int(progress * 100))%"
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Percentage label at top
            Text(percentageText)
                .font(.paceRounded(size: 16, weight: .bold))
                .foregroundColor(Color(.label))
                .opacity(progress > 0 ? 1 : 0.3)
            
            // Food bar with fill effect (no text inside)
            ZStack(alignment: .bottom) {
                // Background layer: semi-transparent food image
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(0.3)
                    .frame(width: 80, height: height)
                
                // Fill layer: opaque food image clipped by fill height
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: height)
                    .mask(
                        VStack(spacing: 0) {
                            Spacer()
                            Rectangle()
                                .frame(height: height * progress)
                        }
                        .frame(height: height)
                    )
                    .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.75), value: progress)
            }
            .frame(width: 80, height: height)
            
            // Label at bottom
            Text(label)
                .font(.paceRounded(size: 13, weight: .semibold))
                .foregroundColor(Color(.secondaryLabel))
            
            // Target value hint
            Text("\(total)g")
                .font(.paceRounded(size: 11, weight: .medium))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value) \(settings.localized(.consumed)), \(total)g")
    }
}

#Preview {
    DashboardBarsView(
        consumedCalories: 730,
        totalCalories: 2647,
        consumedProtein: 85,
        totalProtein: 165,
        consumedCarbs: 120,
        totalCarbs: 220,
        consumedFat: 45,
        totalFat: 73,
        activityLevel: .medium,
        onActivityLevelTap: {}
    )
    .background(Color(.systemBackground))
}
