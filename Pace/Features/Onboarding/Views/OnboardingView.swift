//
//  OnboardingView.swift
//  Pace
//
//  Onboarding flow for new users.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Binding var isCompleted: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep: Step = .welcome
    @State private var userProfile = UserProfile.default
    @Environment(\.colorScheme) private var colorScheme
    
    enum Step: CaseIterable {
        case welcome
        case bodyData
        case goalConfirm
        
        var progress: Double {
            switch self {
            case .welcome: return 0.33
            case .bodyData: return 0.66
            case .goalConfirm: return 1.0
            }
        }
    }
    
    private var settings: AppSettingsManager { AppSettingsManager.shared }
    private var canGoBack: Bool {
        currentStep != .welcome
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress indicator
                    progressBar
                        .padding(.top, 60)
                        .padding(.horizontal, 40)
                    
                    // Content based on step
                    contentView
                        .padding(.top, 40)
                    
                    Spacer()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: currentStep)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if canGoBack {
                        Button(action: goBack) {
                            Image(systemName: "arrow.left")
                                .font(.paceRounded(.title3, weight: .semibold))
                                .foregroundColor(Color(.label))
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if currentStep == .welcome {
                        Button(action: skipOnboarding) {
                            Text(settings.language == .chinese ? "跳过" : "Skip")
                                .font(.paceRounded(.body, weight: .medium))
                                .foregroundColor(Color(.secondaryLabel))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation
    
    private func goBack() {
        if let currentIndex = Step.allCases.firstIndex(of: currentStep),
           currentIndex > 0 {
            withAnimation {
                currentStep = Step.allCases[currentIndex - 1]
            }
        }
    }
    
    private func goNext() {
        if let currentIndex = Step.allCases.firstIndex(of: currentStep),
           currentIndex < Step.allCases.count - 1 {
            withAnimation {
                currentStep = Step.allCases[currentIndex + 1]
            }
        }
    }
    
    private func skipOnboarding() {
        // Use default profile
        UserProfile.default.save()
        settings.hasCompletedOnboarding = true
        withAnimation {
            isCompleted = true
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(.tertiarySystemFill))
                    .frame(height: 4)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(red: 1, green: 0.267, blue: 0))
                    .frame(width: geo.size.width * currentStep.progress, height: 4)
                    .animation(.spring(response: 0.4), value: currentStep)
            }
        }
        .frame(height: 4)
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var contentView: some View {
        switch currentStep {
        case .welcome:
            WelcomeStep {
                goNext()
            }
        case .bodyData:
            BodyDataStep(profile: $userProfile) {
                goNext()
            }
        case .goalConfirm:
            GoalConfirmStep(profile: userProfile) {
                completeOnboarding()
            }
        }
    }
    
    // MARK: - Complete
    
    private func completeOnboarding() {
        userProfile.save()
        settings.hasCompletedOnboarding = true
        withAnimation {
            isCompleted = true
        }
    }
}

// MARK: - Welcome Step

struct WelcomeStep: View {
    let onNext: () -> Void
    private var settings: AppSettingsManager { AppSettingsManager.shared }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Logo / Icon
            ZStack {
                Circle()
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(Color(red: 1, green: 0.267, blue: 0))
            }
            
            // Title
            Text(settings.language == .chinese ? "欢迎来到 Pace" : "Welcome to Pace")
                .font(.paceRounded(size: 36, weight: .black))
                .foregroundColor(Color(.label))
            
            // Subtitle
            Text(settings.language == .chinese 
                 ? "简单记录，健康生活"
                 : "Track simply, live healthy")
                .font(.paceRounded(size: 18, weight: .medium))
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
            
            Spacer()
            
            // Features preview
            VStack(spacing: 16) {
                featureRow(icon: "camera.fill", text: settings.language == .chinese ? "AI 拍照识别食物" : "AI Food Recognition")
                featureRow(icon: "flame.fill", text: settings.language == .chinese ? "智能 TDEE 计算" : "Smart TDEE Calculation")
                featureRow(icon: "chart.ring.3rd", text: settings.language == .chinese ? "直观进度追踪" : "Visual Progress Tracking")
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Start button
            Button(action: onNext) {
                Text(settings.language == .chinese ? "开始" : "Get Started")
                    .font(.paceRounded(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Capsule()
                            .fill(Color(red: 1, green: 0.267, blue: 0))
                    )
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
    
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.paceRounded(size: 20, weight: .semibold))
                .foregroundColor(Color(red: 1, green: 0.267, blue: 0))
                .frame(width: 32)
            
            Text(text)
                .font(.paceRounded(size: 16, weight: .medium))
                .foregroundColor(Color(.label))
            
            Spacer()
        }
    }
}

// MARK: - Body Data Step

struct BodyDataStep: View {
    @Binding var profile: UserProfile
    let onNext: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var age: Double = 25
    @State private var height: Double = 170
    @State private var weight: Double = 70
    @State private var gender: UserProfile.Gender = .male
    @State private var activityLevel: UserProfile.ActivityLevel = .medium
    
    @State private var editingField: EditingField? = nil
    @State private var tempInput: String = ""
    @FocusState private var isInputFocused: Bool
    
    enum EditingField: Identifiable {
        case age, height, weight
        var id: Self { self }
    }
    
    private var settings: AppSettingsManager { AppSettingsManager.shared }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text(settings.language == .chinese ? "让我们了解你" : "Let's get to know you")
                        .font(.paceRounded(size: 28, weight: .black))
                        .foregroundColor(Color(.label))
                    
                    Text(settings.language == .chinese 
                         ? "用于计算你的每日卡路里目标"
                         : "To calculate your daily calorie goals")
                        .font(.paceRounded(size: 15, weight: .medium))
                        .foregroundColor(Color(.secondaryLabel))
                }
                .padding(.top, 20)
                
                // Basic Info Card
                basicInfoSection
                
                // Activity Level Card
                activityLevelSection
                
                // Continue button
                Button(action: {
                    updateProfile()
                    onNext()
                }) {
                    Text(settings.language == .chinese ? "继续" : "Continue")
                        .font(.paceRounded(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            Capsule()
                                .fill(Color(red: 1, green: 0.267, blue: 0))
                        )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 50)
            }
            .padding(.horizontal, 20)
        }
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
            sectionHeader(title: settings.language == .chinese ? "基本信息" : "Basic Info", icon: "person.fill", color: .blue)
            
            VStack(spacing: 16) {
                // Gender Picker
                genderPickerRow
                
                Divider().opacity(0.5)
                
                // Age Slider
                valueSliderRow(
                    icon: "calendar",
                    iconColor: .orange,
                    label: settings.language == .chinese ? "年龄" : "Age",
                    value: age,
                    range: 14...120,
                    unit: settings.language == .chinese ? "岁" : "y",
                    step: 1,
                    onTap: { editingField = .age }
                )
                
                Divider().opacity(0.5)
                
                // Height Slider
                valueSliderRow(
                    icon: "ruler",
                    iconColor: .green,
                    label: settings.language == .chinese ? "身高" : "Height",
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
                    label: settings.language == .chinese ? "体重" : "Weight",
                    value: weight,
                    range: 30...200,
                    unit: "kg",
                    step: 1,
                    onTap: { editingField = .weight }
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
    
    private var activityLevelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: settings.language == .chinese ? "活动等级" : "Activity Level", icon: "flame.fill", color: .red)
            
            VStack(spacing: 0) {
                ForEach(UserProfile.ActivityLevel.allCases, id: \.self) { level in
                    activityLevelRow(level)
                    if level != UserProfile.ActivityLevel.allCases.last {
                        Divider().padding(.leading, 44)
                    }
                }
            }
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemBackground))
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
                .foregroundStyle(Color(.secondaryLabel))
        }
        .padding(.leading, 4)
    }
    
    private var genderPickerRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle")
                .font(.paceRounded(.title3))
                .foregroundStyle(.pink)
                .frame(width: 32)
            
            Text(settings.language == .chinese ? "性别" : "Gender")
                .font(.paceRounded(.body))
                .foregroundStyle(Color(.label))
            
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
                    .foregroundStyle(Color(.label))
                
                Spacer()
                
                Button(action: onTap) {
                    HStack(spacing: 4) {
                        Text("\(Int(value))")
                            .font(.paceRounded(.title3, weight: .bold))
                            .foregroundStyle(Color(.label))
                        Text(unit)
                            .font(.paceRounded(.body))
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            
            Slider(
                value: Binding(
                    get: { value },
                    set: { newValue in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            switch label {
                            case settings.language == .chinese ? "年龄" : "Age": age = round(newValue)
                            case settings.language == .chinese ? "身高" : "Height": height = round(newValue)
                            case settings.language == .chinese ? "体重" : "Weight": weight = round(newValue)
                            default: break
                            }
                        }
                    }
                ),
                in: range,
                step: step
            )
            .tint(iconColor)
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
                        .foregroundStyle(Color(.label))
                    
                    Text(activityDescription(for: level))
                        .font(.paceRounded(.caption))
                        .foregroundStyle(Color(.secondaryLabel))
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
            return settings.language == .chinese ? "每周运动 1-3 次" : "Exercise 1-3 times per week"
        case .high:
            return settings.language == .chinese ? "每周运动 4-5 次" : "Exercise 4-5 times per week"
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
        case .age: return settings.language == .chinese ? "输入年龄" : "Enter Age"
        case .height: return settings.language == .chinese ? "输入身高" : "Enter Height"
        case .weight: return settings.language == .chinese ? "输入体重" : "Enter Weight"
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
    
    private func updateProfile() {
        let dailyCalories = CalorieService.calculateTDEE(
            weight: Int(weight),
            height: Int(height),
            age: Int(age),
            gender: gender,
            activityLevel: activityLevel
        )
        
        profile = UserProfile(
            age: Int(age),
            gender: gender,
            height: Int(height),
            weight: Int(weight),
            activityLevel: activityLevel,
            dailyCalories: dailyCalories
        )
    }
}

// MARK: - Goal Confirm Step

struct GoalConfirmStep: View {
    let profile: UserProfile
    let onComplete: () -> Void
    
    @State private var animateRings = false
    
    private var settings: AppSettingsManager { AppSettingsManager.shared }
    
    private var dailyProtein: Int {
        Int(Double(profile.dailyCalories) * 0.25 / 4.0)
    }
    
    private var dailyFat: Int {
        Int(Double(profile.dailyCalories) * 0.30 / 9.0)
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Title
            Text(settings.language == .chinese ? "你的每日目标" : "Your Daily Goals")
                .font(.paceRounded(size: 28, weight: .black))
                .foregroundColor(Color(.label))
            
            // Main ring visualization (3 rings, no center text)
            ZStack {
                // Background circles
                Circle()
                    .stroke(Color(.tertiarySystemFill), lineWidth: 20)
                    .frame(width: 200, height: 200)
                
                // Progress ring (animated)
                Circle()
                    .trim(from: 0, to: animateRings ? 0.75 : 0)
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color(red: 1, green: 0.267, blue: 0),
                                Color(red: 0.2, green: 0.68, blue: 0.38),
                                Color(red: 0.996, green: 0.56, blue: 0.66)
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 1.0).delay(0.3), value: animateRings)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    animateRings = true
                }
            }
            
            // Macro breakdown (horizontal style like GoalConfirmStep)
            HStack(spacing: 24) {
                macroItem(
                    icon: "flame.fill",
                    value: "\(profile.dailyCalories)",
                    unit: "kcal",
                    color: Color(red: 1, green: 0.267, blue: 0),
                    label: settings.language == .chinese ? "卡路里" : "Calories"
                )
                
                macroItem(
                    icon: "leaf.fill",
                    value: "\(dailyProtein)",
                    unit: "g",
                    color: Color(red: 0.2, green: 0.68, blue: 0.38),
                    label: settings.language == .chinese ? "蛋白质" : "Protein"
                )
                
                macroItem(
                    icon: "drop.fill",
                    value: "\(dailyFat)",
                    unit: "g",
                    color: Color(red: 0.996, green: 0.56, blue: 0.66),
                    label: settings.language == .chinese ? "脂肪" : "Fat"
                )
            }
            .padding(.horizontal, 20)
            
            // Description
            Text(settings.language == .chinese 
                 ? "基于你的基础代谢率和活动量计算得出"
                 : "Calculated from your BMR and activity level")
                .font(.paceRounded(size: 14, weight: .medium))
                .foregroundColor(Color(.tertiaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // Start button (orange capsule style)
            Button(action: onComplete) {
                Text(settings.language == .chinese ? "开始记录" : "Start Tracking")
                    .font(.paceRounded(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Capsule()
                            .fill(Color(red: 1, green: 0.267, blue: 0))
                    )
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
    
    private func macroItem(icon: String, value: String, unit: String, color: Color, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.paceRounded(size: 20, weight: .semibold))
                .foregroundColor(color)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.paceRounded(size: 24, weight: .bold))
                    .foregroundColor(Color(.label))
                Text(unit)
                    .font(.paceRounded(size: 12, weight: .medium))
                    .foregroundColor(Color(.secondaryLabel))
            }
            
            Text(label)
                .font(.paceRounded(size: 12, weight: .medium))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Number Input Sheet

private struct NumberInputSheet: View {
    let title: String
    @Binding var value: String
    @FocusState.Binding var isFocused: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
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
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppSettingsManager.shared.localized(.cancel), action: onCancel)
                        .font(.paceRounded(.body))
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
    OnboardingView(isCompleted: .constant(false))
}
