//
//  AppSettings.swift
//  Pace
//
//  Manages app-wide settings like theme and language.

import SwiftUI

// MARK: - App Theme

enum AppTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var displayNameCN: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色模式"
        case .dark: return "深色模式"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - App Language

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case chinese = "zh"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文"
        }
    }
    
    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .chinese: return "🇨🇳"
        }
    }
}

// MARK: - Settings Manager

@Observable
final class AppSettingsManager {
    static let shared = AppSettingsManager()
    
    var theme: AppTheme {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: "appTheme")
        }
    }
    
    var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "appLanguage")
        }
    }
    
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }
    
    private init() {
        let themeRaw = UserDefaults.standard.string(forKey: "appTheme") ?? AppTheme.system.rawValue
        self.theme = AppTheme(rawValue: themeRaw) ?? .system
        
        // Language: prefer saved choice; otherwise follow device (Chinese → 中文, else English)
        let langRaw: String
        if let saved = UserDefaults.standard.string(forKey: "appLanguage") {
            langRaw = saved
        } else {
            let code = Locale.current.language.languageCode?.identifier ?? "en"
            langRaw = (code == "zh") ? AppLanguage.chinese.rawValue : AppLanguage.english.rawValue
        }
        self.language = AppLanguage(rawValue: langRaw) ?? .english
    }
    
    // MARK: - Localized Strings
    
    func localized(_ key: LocalizedKey) -> String {
        switch language {
        case .english: return key.en
        case .chinese: return key.zh
        }
    }
}

// MARK: - Localized Keys

enum LocalizedKey {
    case welcome
    case welcomeSubtitle
    case settings
    case newFeatures
    case newFeaturesSubtitle
    case appearance
    case language
    case languageSubtitle
    case theme
    case themeSubtitle
    case about
    case version
    case versionSubtitle
    case feedback
    case feedbackSubtitle
    // Dashboard & Food Log
    case activityLevel
    case remainingToday
    case addFood
    case todaysLog
    case done
    case quietSoFar
    case whenYouEatLogHere
    case totalToday
    case caloriesConsumed
    case remaining
    case foodLog
    case noFoodLogged
    case today
    case todayWithComma  // ", Today" / "，今天"
    case whatsNew
    case complete
    // Activity level names
    case activityLevelLow
    case activityLevelMedium
    case activityLevelHigh
    // Gender
    case genderMale
    case genderFemale
    // Profile
    case age
    case height
    case weight
    case bmr
    case tdee
    case calcResult
    case bmrTdeeHint
    // Sticker / Photo
    case stickerSaved
    case saved  // alert title: "Saved" / "已保存"
    case saveFailed  // alert title: "Save failed" / "保存失败"
    case allowPhotoAccess
    case delete
    case edit
    case editFood
    case cancel
    case save
    case name
    case portion
    case nutrition
    case calories
    case carbs
    case protein
    case fat
    case carbsLabel   // short for macro row: "Carbs"
    case proteinLabel
    case fatLabel
    case invalidInput
    case validNumbersHint
    // Camera
    case analyzingFood
    case placeInFrame
    case added
    case processing
    case retake
    case tryAgain
    case fillInDetails
    case confirm
    case addAnyway
    case foodInfo
    case macrosGrams
    case foodNamePlaceholder  // TextField placeholder
    // Feedback
    case feedbackContent
    case feedbackHint
    case feedbackPlaceholder
    case send
    case thankYou
    case ok
    // New Features copy
    case featureAITitle
    case featureAIDesc
    case featureTDEETitle
    case featureTDEEDesc
    case featureStickerTitle
    case featureStickerDesc
    case featureLiveTitle
    case featureLiveDesc
    case proteinGram  // e.g. "g protein"
    case fatGram      // e.g. "g fat"
    case basicInfo
    case yearsOld
    case genderLabel
    case activityLevelSection
    case support
    case profile
    case kcalPerDay
    // Body Data
    case healthProfile
    case bodyData
    case bodyDataSubtitle
    case dailyTargets
    case enterAge
    case enterHeight
    case enterWeight
    case homeTab
    case settingsTab
    case dailyFoodLog
    case noFoodToday
    case foodDetail
    // Onboarding
    case viewOnboarding
    case viewOnboardingSubtitle
    case deleteConfirmation
    case deleteConfirmationMessage
    case noFoodThisDay
    case noFoodFuture
    case consumed
    // Accessibility (VoiceOver labels/hints)
    case accBack
    case accChangeActivityLevel
    case accCaloriesProgress
    case accProteinProgress
    case accCarbsProgress
    case accFatProgress
    case accCrop
    case accShare
    // Formula Details & Citations
    case howCalculated
    case bmrFullName
    case bmrFormula
    case bmrFormulaMale
    case bmrFormulaFemale
    case tdeeFullName
    case tdeeFormula
    case activityMultipliers
    case activityMultiplierLow
    case activityMultiplierMedium
    case activityMultiplierHigh
    case scientificReference
    case mifflinReference
    case activityReference

    var en: String {
        switch self {
        case .welcome: return "Welcome ^ ^"
        case .welcomeSubtitle: return "What I do today is important because I am exchanging a day of my life for it."
        case .settings: return "Settings"
        case .newFeatures: return "New Features"
        case .newFeaturesSubtitle: return "See what's new in this version"
        case .appearance: return "Appearance"
        case .language: return "Language"
        case .languageSubtitle: return "Choose your preferred language"
        case .theme: return "Theme"
        case .themeSubtitle: return "Switch between light and dark mode"
        case .about: return "About"
        case .version: return "Version"
        case .versionSubtitle: return "Current app version"
        case .feedback: return "Feedback"
        case .feedbackSubtitle: return "Share your thoughts in the App Store"
        case .activityLevel: return "Activity Level"
        case .remainingToday: return "Remaining Today"
        case .addFood: return "Add Food"
        case .todaysLog: return "Today's Log"
        case .done: return "Done"
        case .quietSoFar: return "Quiet so far"
        case .whenYouEatLogHere: return "When you eat, simply log it here."
        case .totalToday: return "Total today"
        case .caloriesConsumed: return "calories consumed"
        case .remaining: return "Remaining"
        case .foodLog: return "Food Log"
        case .noFoodLogged: return "No food logged"
        case .today: return "Today"
        case .todayWithComma: return ", Today"
        case .whatsNew: return "What's New"
        case .complete: return "Done"
        case .activityLevelLow: return "Low"
        case .activityLevelMedium: return "Medium"
        case .activityLevelHigh: return "High"
        case .genderMale: return "Male"
        case .genderFemale: return "Female"
        case .age: return "Age"
        case .height: return "Height"
        case .weight: return "Weight"
        case .bmr: return "BMR"
        case .tdee: return "TDEE"
        case .calcResult: return "Result"
        case .bmrTdeeHint: return "BMR = Basal Metabolic Rate (Mifflin-St Jeor); TDEE = BMR × activity factor"
        case .stickerSaved: return "Sticker saved to Photos"
        case .saved: return "Saved"
        case .saveFailed: return "Save failed"
        case .allowPhotoAccess: return "Please allow photo library access in Settings"
        case .delete: return "Delete"
        case .edit: return "Edit"
        case .editFood: return "Edit Food"
        case .cancel: return "Cancel"
        case .save: return "Save"
        case .name: return "Name"
        case .portion: return "Portion"
        case .nutrition: return "Nutrition"
        case .calories: return "Calories"
        case .carbs: return "Carbs (g)"
        case .protein: return "Protein (g)"
        case .fat: return "Fat (g)"
        case .carbsLabel: return "Carbs"
        case .proteinLabel: return "Protein"
        case .fatLabel: return "Fat"
        case .invalidInput: return "Invalid input"
        case .validNumbersHint: return "Please enter valid numbers for nutrition."
        case .analyzingFood: return "Analyzing food..."
        case .placeInFrame: return "Please place the object\nwithin the frame"
        case .added: return "Added!"
        case .processing: return "Processing..."
        case .retake: return "Retake"
        case .tryAgain: return "Try Again"
        case .fillInDetails: return "Fill in Details"
        case .confirm: return "Confirm"
        case .addAnyway: return "Add Anyway"
        case .foodInfo: return "Food Info"
        case .macrosGrams: return "Macros (grams)"
        case .foodNamePlaceholder: return "Food name"
        case .feedbackContent: return "Feedback"
        case .feedbackHint: return "Your feedback helps us improve."
        case .feedbackPlaceholder: return "Describe your feedback or issue…"
        case .send: return "Send"
        case .thankYou: return "Thank you"
        case .ok: return "OK"
        case .featureAITitle: return "AI Food Recognition"
        case .featureAIDesc: return "Take a photo of your food and let AI recognize it instantly with calorie estimation."
        case .featureTDEETitle: return "Activity-Based TDEE"
        case .featureTDEEDesc: return "Calorie goals automatically adjust based on your daily activity level."
        case .featureStickerTitle: return "Food Stickers"
        case .featureStickerDesc: return "Long press on food stickers to save them to your photo library with transparent background."
        case .featureLiveTitle: return "Live Activity"
        case .featureLiveDesc: return "Track your daily calorie progress right from your Lock Screen and Dynamic Island."
        case .proteinGram: return "g protein"
        case .fatGram: return "g fat"
        case .basicInfo: return "Basic Info"
        case .yearsOld: return "years"
        case .genderLabel: return "Gender"
        case .activityLevelSection: return "Activity Level"
        case .support: return "Support"
        case .profile: return "Profile"
        case .kcalPerDay: return "kcal/day"
        case .healthProfile: return "Health Profile"
        case .bodyData: return "Body Data"
        case .bodyDataSubtitle: return "Manage your body metrics for TDEE calculation"
        case .dailyTargets: return "Daily Targets"
        case .enterAge: return "Enter Age"
        case .enterHeight: return "Enter Height"
        case .enterWeight: return "Enter Weight"
        case .homeTab: return "Home"
        case .settingsTab: return "Settings"
        case .dailyFoodLog: return "Daily Food Log"
        case .noFoodToday: return "No food recorded today"
        case .foodDetail: return "Food Detail"
        // Onboarding
        case .viewOnboarding: return "View Onboarding"
        case .viewOnboardingSubtitle: return "Preview the welcome guide"
        case .deleteConfirmation: return "Delete Food"
        case .deleteConfirmationMessage: return "Are you sure you want to delete this food record?"
        case .noFoodThisDay: return "No food recorded on this day"
        case .noFoodFuture: return "This day hasn't arrived yet"
        case .consumed: return "Consumed"
        case .accBack: return "Back"
        case .accChangeActivityLevel: return "Double tap to change activity level"
        case .accCaloriesProgress: return "Calories progress"
        case .accProteinProgress: return "Protein progress"
        case .accCarbsProgress: return "Carbs progress"
        case .accFatProgress: return "Fat progress"
        case .accCrop: return "Crop image"
        case .accShare: return "Share"
        case .howCalculated: return "How is this calculated?"
        case .bmrFullName: return "Basal Metabolic Rate"
        case .bmrFormula: return "BMR Formula (Mifflin-St Jeor)"
        case .bmrFormulaMale: return "Male: 10 × weight(kg) + 6.25 × height(cm) − 5 × age + 5"
        case .bmrFormulaFemale: return "Female: 10 × weight(kg) + 6.25 × height(cm) − 5 × age − 161"
        case .tdeeFullName: return "Total Daily Energy Expenditure"
        case .tdeeFormula: return "TDEE = BMR × Activity Multiplier"
        case .activityMultipliers: return "Activity Multipliers"
        case .activityMultiplierLow: return "Low (sedentary): × 1.2"
        case .activityMultiplierMedium: return "Medium (moderate exercise): × 1.55"
        case .activityMultiplierHigh: return "High (intense exercise): × 1.725"
        case .scientificReference: return "Scientific References"
        case .mifflinReference: return "Mifflin MD, et al. \"A new predictive equation for resting energy expenditure in healthy individuals.\" Am J Clin Nutr. 1990;51(2):241-247."
        case .activityReference: return "\"Dietary Reference Intakes for Energy.\" National Academies Press, 2005."
        }
    }

    var zh: String {
        switch self {
        case .welcome: return "欢迎 ^ ^"
        case .welcomeSubtitle: return "今天做的事很重要，因为我用生命中的一天来交换。"
        case .settings: return "设置"
        case .newFeatures: return "新功能"
        case .newFeaturesSubtitle: return "查看此版本的新功能"
        case .appearance: return "外观"
        case .language: return "语言"
        case .languageSubtitle: return "选择你偏好的语言"
        case .theme: return "主题"
        case .themeSubtitle: return "切换浅色和深色模式"
        case .about: return "关于"
        case .version: return "版本"
        case .versionSubtitle: return "当前应用版本"
        case .feedback: return "意见反馈"
        case .feedbackSubtitle: return "在 App Store 分享你的想法"
        case .activityLevel: return "活动等级"
        case .remainingToday: return "今日剩余"
        case .addFood: return "添加食物"
        case .todaysLog: return "今日记录"
        case .done: return "完成"
        case .quietSoFar: return "还没有记录"
        case .whenYouEatLogHere: return "吃过的东西在这里记录。"
        case .totalToday: return "今日合计"
        case .caloriesConsumed: return "已摄入卡路里"
        case .remaining: return "剩余"
        case .foodLog: return "食物记录"
        case .noFoodLogged: return "暂无记录"
        case .today: return "今天"
        case .todayWithComma: return "，今天"
        case .whatsNew: return "新功能"
        case .complete: return "完成"
        case .activityLevelLow: return "低"
        case .activityLevelMedium: return "中"
        case .activityLevelHigh: return "高"
        case .genderMale: return "男"
        case .genderFemale: return "女"
        case .age: return "年龄"
        case .height: return "身高"
        case .weight: return "体重"
        case .bmr: return "BMR"
        case .tdee: return "TDEE"
        case .calcResult: return "计算结果"
        case .bmrTdeeHint: return "BMR = 基础代谢率（Mifflin-St Jeor）；TDEE = BMR × 活动系数"
        case .stickerSaved: return "贴纸已保存到相册"
        case .saved: return "已保存"
        case .saveFailed: return "保存失败"
        case .allowPhotoAccess: return "请在设置中允许访问相册"
        case .delete: return "删除"
        case .edit: return "编辑"
        case .editFood: return "编辑食物"
        case .cancel: return "取消"
        case .save: return "保存"
        case .name: return "名称"
        case .portion: return "份量"
        case .nutrition: return "营养"
        case .calories: return "卡路里"
        case .carbs: return "碳水 (g)"
        case .protein: return "蛋白质 (g)"
        case .fat: return "脂肪 (g)"
        case .carbsLabel: return "碳水"
        case .proteinLabel: return "蛋白质"
        case .fatLabel: return "脂肪"
        case .invalidInput: return "输入无效"
        case .validNumbersHint: return "请填写有效的营养数值。"
        case .analyzingFood: return "正在识别食物..."
        case .placeInFrame: return "请将物体放在框内"
        case .added: return "已添加！"
        case .processing: return "处理中..."
        case .retake: return "重拍"
        case .tryAgain: return "再试一次"
        case .fillInDetails: return "填写详情"
        case .confirm: return "确认"
        case .addAnyway: return "仍然添加"
        case .foodInfo: return "食物信息"
        case .macrosGrams: return "宏量 (克)"
        case .foodNamePlaceholder: return "食物名称"
        case .feedbackContent: return "反馈内容"
        case .feedbackHint: return "你的意见对我们很有帮助。"
        case .feedbackPlaceholder: return "请描述你的建议或问题…"
        case .send: return "发送"
        case .thankYou: return "感谢反馈"
        case .ok: return "确定"
        case .featureAITitle: return "AI 食物识别"
        case .featureAIDesc: return "拍照识别食物，AI 自动估算卡路里和营养成分。"
        case .featureTDEETitle: return "基于活动量的 TDEE"
        case .featureTDEEDesc: return "根据你的日常活动量自动调整每日卡路里目标。"
        case .featureStickerTitle: return "食物贴纸"
        case .featureStickerDesc: return "长按食物贴纸可保存透明背景的 PNG 图片到相册。"
        case .featureLiveTitle: return "实时活动"
        case .featureLiveDesc: return "在锁屏和灵动岛实时追踪每日卡路里进度。"
        case .proteinGram: return "g 蛋白"
        case .fatGram: return "g 脂肪"
        case .basicInfo: return "基本信息"
        case .yearsOld: return "岁"
        case .genderLabel: return "性别"
        case .activityLevelSection: return "活动等级"
        case .support: return "支持"
        case .profile: return "个人资料"
        case .kcalPerDay: return "kcal/天"
        case .healthProfile: return "健康档案"
        case .bodyData: return "身体数据"
        case .bodyDataSubtitle: return "管理用于 TDEE 计算的身体指标"
        case .dailyTargets: return "每日目标"
        case .enterAge: return "输入年龄"
        case .enterHeight: return "输入身高"
        case .enterWeight: return "输入体重"
        case .homeTab: return "首页"
        case .settingsTab: return "设置"
        case .dailyFoodLog: return "今日饮食记录"
        case .noFoodToday: return "今天还没有记录食物"
        case .foodDetail: return "食物详情"
        // Onboarding
        case .viewOnboarding: return "查看引导"
        case .viewOnboardingSubtitle: return "预览欢迎指南"
        case .deleteConfirmation: return "删除食物"
        case .deleteConfirmationMessage: return "确定要删除这条食物记录吗？"
        case .noFoodThisDay: return "这一天没有记录"
        case .noFoodFuture: return "还没有到这一天"
        case .consumed: return "已摄入"
        case .accBack: return "返回"
        case .accChangeActivityLevel: return "双击可更改活动等级"
        case .accCaloriesProgress: return "卡路里进度"
        case .accProteinProgress: return "蛋白质进度"
        case .accCarbsProgress: return "碳水进度"
        case .accFatProgress: return "脂肪进度"
        case .accCrop: return "裁切图片"
        case .accShare: return "分享"
        case .howCalculated: return "计算方式"
        case .bmrFullName: return "基础代谢率"
        case .bmrFormula: return "BMR 公式（Mifflin-St Jeor）"
        case .bmrFormulaMale: return "男性：10 × 体重(kg) + 6.25 × 身高(cm) − 5 × 年龄 + 5"
        case .bmrFormulaFemale: return "女性：10 × 体重(kg) + 6.25 × 身高(cm) − 5 × 年龄 − 161"
        case .tdeeFullName: return "每日总能量消耗"
        case .tdeeFormula: return "TDEE = BMR × 活动系数"
        case .activityMultipliers: return "活动系数"
        case .activityMultiplierLow: return "低（久坐）：× 1.2"
        case .activityMultiplierMedium: return "中（适度运动）：× 1.55"
        case .activityMultiplierHigh: return "高（高强度运动）：× 1.725"
        case .scientificReference: return "科学参考文献"
        case .mifflinReference: return "Mifflin MD 等人，《健康个体静息能量消耗的新预测方程》，美国临床营养学杂志，1990年第51卷第2期，241-247页。"
        case .activityReference: return "《能量的膳食参考摄入量》，美国国家科学院出版社，2005年。"
        }
    }
}
