//
//  ProfileView.swift
//  Pace
//

import SwiftUI
import UIKit

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let viewModel: DashboardViewModel
    private var settings: AppSettingsManager { AppSettingsManager.shared }
    
    // MARK: - State
    @State private var age: Double = 25
    @State private var gender: UserProfile.Gender = .male
    @State private var height: Double = 170
    @State private var weight: Double = 70
    @State private var activityLevel: UserProfile.ActivityLevel = .low
    
    // MARK: - Editing State
    @State private var editingField: EditingField? = nil
    @State private var tempInput: String = ""
    @FocusState private var isInputFocused: Bool
    
    enum EditingField: Identifiable {
        case age, height, weight
        var id: Self { self }
    }
    
    // MARK: - Computed
    private var bmr: Double {
        CalorieService.calculateBMR(weight: Int(weight), height: Int(height), age: Int(age), gender: gender)
    }
    
    private var tdee: Int {
        CalorieService.calculateTDEE(
            weight: Int(weight),
            height: Int(height),
            age: Int(age),
            gender: gender,
            activityLevel: activityLevel
        )
    }
    
    private var dailyProtein: Int {
        Int(Double(tdee) * 0.25 / 4.0)
    }
    
    private var dailyFat: Int {
        Int(Double(tdee) * 0.30 / 9.0)
    }
    
    // MARK: - Colors
    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.02, green: 0.02, blue: 0.02)
            : Color(red: 0.98, green: 0.98, blue: 0.98)
    }
    
    private var cardBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.15, green: 0.15, blue: 0.16)
            : Color(.secondarySystemBackground)
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark
            ? Color(red: 0.996, green: 0.976, blue: 0.937)
            : Color(red: 0.1, green: 0.1, blue: 0.1)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Basic Info Cards
                    basicInfoSection
                    
                    // Activity Level Card
                    activityLevelSection
                    
                    // Calculation Results Card
                    calculationResultsSection
                    
                    // Daily Targets Preview
                    dailyTargetsSection
                }
                .padding()
            }
            .background(backgroundColor.ignoresSafeArea())
            .navigationTitle(settings.localized(.profile))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { saveProfile() }) {
                        Image(systemName: "checkmark")
                            .font(.paceRounded(.body, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .onAppear(perform: loadingProfile)
        .sheet(item: $editingField) { field in
            NumberInputSheet(
                title: inputSheetTitle(for: field),
                value: $tempInput,
                isFocused: $isInputFocused,
                onConfirm: { confirmInput(for: field) },
                onCancel: { editingField = nil }
            )
            .onAppear {
                tempInput = String(format: "%d", Int(currentValue(for: field)))
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isInputFocused = true
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: settings.localized(.basicInfo), icon: "person.fill", color: .blue)
            
            VStack(spacing: 16) {
                // Gender Picker
                genderPickerRow
                
                Divider().opacity(0.5)
                
                // Age Slider
                valueSliderRow(
                    icon: "calendar",
                    iconColor: .orange,
                    label: settings.localized(.age),
                    value: age,
                    range: 14...120,
                    unit: settings.localized(.yearsOld),
                    step: 1,
                    onTap: { editingField = .age }
                )
                
                Divider().opacity(0.5)
                
                // Height Slider
                valueSliderRow(
                    icon: "ruler",
                    iconColor: .green,
                    label: settings.localized(.height),
                    value: height,
                    range: 100...250,
                    unit: "cm",
                    step: 1,
                    onTap: { editingField = .height }
                )
                
                Divider().opacity(0.5)
                
                // Weight Slider
                valueSliderRow(
                    icon: "scalemass",
                    iconColor: .purple,
                    label: settings.localized(.weight),
                    value: weight,
                    range: 30...200,
                    unit: "kg",
                    step: 1,
                    onTap: { editingField = .weight }
                )
            }
            .padding()
            .background(cardBackground, in: RoundedRectangle(cornerRadius: 20))
        }
    }
    
    private var genderPickerRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle")
                .font(.paceRounded(.title3))
                .foregroundStyle(.pink)
                .frame(width: 32)
            
            Text(settings.localized(.genderLabel))
                .font(.paceRounded(.body))
                .foregroundStyle(primaryTextColor)
            
            Spacer()
            
            Picker("", selection: $gender) {
                ForEach(UserProfile.Gender.allCases, id: \.self) { g in
                    Text(settings.localized(g.localizedKey))
                        .tag(g)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 140)
        }
    }
    
    private var activityLevelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: settings.localized(.activityLevelSection), icon: "flame.fill", color: .red)
            
            VStack(spacing: 0) {
                ForEach(UserProfile.ActivityLevel.allCases, id: \.self) { level in
                    activityLevelRow(level)
                    if level != UserProfile.ActivityLevel.allCases.last {
                        Divider().padding(.leading, 44)
                    }
                }
            }
            .padding(.vertical, 8)
            .background(cardBackground, in: RoundedRectangle(cornerRadius: 20))
        }
    }
    
    private func activityLevelRow(_ level: UserProfile.ActivityLevel) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                activityLevel = level
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(activityLevel == level ? Color.red.opacity(0.15) : Color.clear)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: activityIcon(for: level))
                        .font(.paceRounded(.body, weight: .medium))
                        .foregroundStyle(activityLevel == level ? .red : .secondary)
                }
                .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(settings.localized(level.localizedKey))
                        .font(.paceRounded(.body))
                        .foregroundStyle(primaryTextColor)
                    
                    Text(activityDescription(for: level))
                        .font(.paceRounded(.caption))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if activityLevel == level {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.paceRounded(.title3))
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
    
    private var calculationResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: settings.localized(.calcResult), icon: "calculator", color: .cyan)
            
            HStack(spacing: 12) {
                // BMR Card
                metricCard(
                    title: settings.localized(.bmr),
                    value: Int(round(bmr)),
                    unit: settings.localized(.kcalPerDay),
                    color: .orange,
                    icon: "bed.double.fill"
                )
                
                // TDEE Card
                metricCard(
                    title: settings.localized(.tdee),
                    value: tdee,
                    unit: settings.localized(.kcalPerDay),
                    color: .red,
                    icon: "flame.fill"
                )
            }
            
            Text(settings.localized(.bmrTdeeHint))
                .font(.paceRounded(.caption))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
        }
    }
    
    private var dailyTargetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: settings.localized(.dailyTargets), icon: "target", color: .green)
            
            VStack(spacing: 16) {
                // Calories
                targetRow(
                    icon: "flame.fill",
                    color: Color(red: 1, green: 0.267, blue: 0),
                    label: settings.localized(.calories),
                    value: tdee,
                    unit: "kcal"
                )
                
                Divider().opacity(0.5)
                
                // Protein
                targetRow(
                    icon: "leaf.fill",
                    color: Color(red: 0.2, green: 0.68, blue: 0.38),
                    label: settings.localized(.proteinLabel),
                    value: dailyProtein,
                    unit: "g"
                )
                
                Divider().opacity(0.5)
                
                // Fat
                targetRow(
                    icon: "drop.fill",
                    color: Color(red: 0.996, green: 0.56, blue: 0.66),
                    label: settings.localized(.fatLabel),
                    value: dailyFat,
                    unit: "g"
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.green.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.paceRounded(.caption, weight: .semibold))
                .foregroundStyle(color)
            Text(title)
                .font(.paceRounded(.subheadline, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.leading, 4)
    }
    
    private func valueSliderRow(
        icon: String,
        iconColor: Color,
        label: String,
        value: Double,
        range: ClosedRange<Double>,
        unit: String,
        step: Double,
        onTap: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.paceRounded(.title3))
                    .foregroundStyle(iconColor)
                    .frame(width: 32)
                
                Text(label)
                    .font(.paceRounded(.body))
                    .foregroundStyle(primaryTextColor)
                
                Spacer()
                
                Button(action: onTap) {
                    HStack(spacing: 4) {
                        Text("\(Int(value))")
                            .font(.paceRounded(.title3, weight: .bold))
                            .foregroundStyle(primaryTextColor)
                        Text(unit)
                            .font(.paceRounded(.body))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            
            Slider(value: Binding(
                get: { value },
                set: { newValue in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        switch label {
                        case settings.localized(.age): age = round(newValue)
                        case settings.localized(.height): height = round(newValue)
                        case settings.localized(.weight): weight = round(newValue)
                        default: break
                        }
                    }
                }
            ), in: range, step: step)
            .tint(iconColor)
        }
    }
    
    private func metricCard(title: String, value: Int, unit: String, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.paceRounded(.caption))
                    .foregroundStyle(color)
                Text(title)
                    .font(.paceRounded(.caption, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(value)")
                    .font(.paceRounded(.title, weight: .bold))
                    .foregroundStyle(primaryTextColor)
                    .contentTransition(.numericText())
                Text(unit)
                    .font(.paceRounded(.caption))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func targetRow(icon: String, color: Color, label: String, value: Int, unit: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.paceRounded(.body))
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(label)
                .font(.paceRounded(.body))
                .foregroundStyle(primaryTextColor)
            
            Spacer()
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(value)")
                    .font(.paceRounded(.title3, weight: .bold))
                    .foregroundStyle(color)
                    .contentTransition(.numericText())
                Text(unit)
                    .font(.paceRounded(.caption))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func activityIcon(for level: UserProfile.ActivityLevel) -> String {
        switch level {
        case .low: return "figure.seated.side"
        case .medium: return "figure.walk"
        case .high: return "figure.run"
        }
    }
    
    private func activityDescription(for level: UserProfile.ActivityLevel) -> String {
        switch level {
        case .low:
            return settings.language == .chinese ? "久坐不动，很少运动" : "Sedentary, little exercise"
        case .medium:
            return settings.language == .chinese ? "每周运动 3-5 次" : "Exercise 3-5 times/week"
        case .high:
            return settings.language == .chinese ? "每周运动 6-7 次" : "Exercise 6-7 times/week"
        }
    }
    
    private func currentValue(for field: EditingField) -> Double {
        switch field {
        case .age: return age
        case .height: return height
        case .weight: return weight
        }
    }
    
    private func inputSheetTitle(for field: EditingField) -> String {
        switch field {
        case .age: return settings.localized(.enterAge)
        case .height: return settings.localized(.enterHeight)
        case .weight: return settings.localized(.enterWeight)
        }
    }
    
    private func confirmInput(for field: EditingField) {
        if let newValue = Double(tempInput), newValue > 0 {
            withAnimation {
                switch field {
                case .age: age = min(max(newValue, 14), 120)
                case .height: height = min(max(newValue, 100), 250)
                case .weight: weight = min(max(newValue, 30), 200)
                }
            }
        }
        editingField = nil
    }
    
    private func loadingProfile() {
        let p = viewModel.userProfile
        age = Double(p.age)
        gender = p.gender
        height = Double(p.height)
        weight = Double(p.weight)
        activityLevel = p.activityLevel
    }
    
    private func saveProfile() {
        viewModel.updateProfile(
            age: Int(age),
            gender: gender,
            height: Int(height),
            weight: Int(weight),
            activityLevel: activityLevel
        )
        dismiss()
    }
}

// MARK: - Number Input Sheet

private struct NumberInputSheet: View {
    let title: String
    @Binding var value: String
    @FocusState.Binding var isFocused: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("", text: $value)
                    .font(.paceRounded(.title, weight: .bold))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($isFocused)
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 40)
            .background(Color(.systemBackground))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { 
                        onCancel()
                        dismiss() 
                    }) {
                        Image(systemName: "xmark")
                            .font(.paceRounded(.body, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppSettingsManager.shared.localized(.save)) {
                        onConfirm()
                    }
                    .font(.paceRounded(.body, weight: .semibold))
                }
            }
        }
    }
}

#Preview {
    ProfileView(viewModel: DashboardViewModel())
}
