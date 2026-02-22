//
//  HomeView.swift
//  Pace
//
//  Home dashboard with rings visualization and activity level selector.
//

import SwiftUI
import SwiftData
import ActivityKit

struct HomeView: View {
    @Query private var allEntries: [FoodEntry]
    @State private var viewModel = DashboardViewModel()
    @State private var showingActivityPicker = false
    @State private var showingProfile = false
    @Environment(\.colorScheme) private var colorScheme
    private var settings: AppSettingsManager { AppSettingsManager.shared }
    
    let onAddFood: () -> Void

    // MARK: - Launch Animation State
    @State private var hasAppeared = false
    
    init(onAddFood: @escaping () -> Void = {}) {
        self.onAddFood = onAddFood
        _allEntries = Query(sort: \FoodEntry.timestamp, order: .reverse)
    }
    
    private var consumedCalories: Int {
        viewModel.consumedCalories(from: allEntries)
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header: Activity Level selector
                activityLevelHeader
                    .padding(.top, 80)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : -20)
                    .animation(.easeOut(duration: 0.4).delay(0.1), value: hasAppeared)
                
                // Main visualization: Rings
                mainVisualization
                    .padding(.top, 60)
                    .scaleEffect(hasAppeared ? 1 : 0.8)
                    .opacity(hasAppeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: hasAppeared)
                
                // Stats Row
                statsRow
                    .padding(.top, 30)
                    .opacity(hasAppeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.4), value: hasAppeared)
                
                Spacer()
                
                // Add Food Button (New Style)
                addFoodButton
                    .padding(.bottom, 50)
                    .opacity(hasAppeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.5), value: hasAppeared)
            }
        }
        .onAppear {
            guard !hasAppeared else { return }
            DispatchQueue.main.async {
                hasAppeared = true
            }
            // Start Live Activity on app launch
            viewModel.startLiveActivity(from: allEntries)
        }
        .onChange(of: allEntries) { _, newEntries in
            // Update Live Activity when food entries change
            viewModel.updateLiveActivity(from: newEntries)
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView(viewModel: viewModel)
                .environment(\.font, Font.system(.body, design: .rounded))
        }
        .sheet(isPresented: $showingActivityPicker) {
            ActivityLevelPickerSheet(
                selectedLevel: viewModel.activityLevel,
                onSelect: { level in
                    viewModel.updateActivityLevel(level)
                }
            )
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Colors
    
    private var textColor: Color {
        Color(.label)
    }
    
    private var secondaryTextColor: Color {
        Color(.secondaryLabel)
    }
    
    // MARK: - Subviews
    
    private var activityLevelHeader: some View {
        Button {
            showingActivityPicker = true
        } label: {
            HStack(spacing: 8) {
                Text(settings.localized(viewModel.activityLevel.localizedKey))
                    .font(.paceRounded(size: 40, weight: .black))
                    .foregroundColor(textColor)
                    .contentTransition(.numericText())
                
                Image(systemName: "chevron.right")
                    .font(.paceRounded(size: 20, weight: .semibold))
                    .foregroundColor(secondaryTextColor)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var mainVisualization: some View {
        Button {
            showingProfile = true
        } label: {
            DashboardRingsView(
                consumedCalories: consumedCalories,
                totalCalories: viewModel.dailyCalories,
                consumedProtein: viewModel.consumedProtein(from: allEntries),
                totalProtein: viewModel.dailyProtein,
                consumedFat: viewModel.consumedFat(from: allEntries),
                totalFat: viewModel.dailyFat
            )
        }
        .buttonStyle(.plain)
    }
    
    private var statsRow: some View {
        let remainingCal = max(0, viewModel.dailyCalories - consumedCalories)
        let remainingProtein = max(0, viewModel.dailyProtein - viewModel.consumedProtein(from: allEntries))
        let remainingFat = max(0, viewModel.dailyFat - viewModel.consumedFat(from: allEntries))
        
        return HStack(spacing: 24) {
            macroItem(icon: "flame.fill", value: "\(remainingCal)", unit: "kcal", color: Color(red: 1, green: 0.267, blue: 0))
            macroItem(icon: "leaf.fill", value: "\(remainingProtein)", unit: "g", color: Color(red: 0.2, green: 0.68, blue: 0.38))
            macroItem(icon: "drop.fill", value: "\(remainingFat)", unit: "g", color: Color(red: 0.996, green: 0.56, blue: 0.66))
        }
        .padding(.horizontal, 40)
    }
    
    private func macroItem(icon: String, value: String, unit: String, color: Color) -> some View {
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
        }
        .frame(maxWidth: .infinity)
    }
    
    private var addFoodButton: some View {
        Button {
            onAddFood()
        } label: {
            Text(settings.localized(.addFood))
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

// MARK: - Activity Level Picker Sheet (Settings Style)

struct ActivityLevelPickerSheet: View {
    let selectedLevel: UserProfile.ActivityLevel
    let onSelect: (UserProfile.ActivityLevel) -> Void
    @Environment(\.dismiss) private var dismiss
    private var settings: AppSettingsManager { AppSettingsManager.shared }
    
    var body: some View {
        VStack(spacing: 0) {
            Text(settings.localized(.activityLevel))
                .font(.paceRounded(.headline, weight: .black))
                .padding()
            
            VStack(spacing: 8) {
                ForEach(UserProfile.ActivityLevel.allCases, id: \.self) { level in
                    Button {
                        onSelect(level)
                        dismiss()
                    } label: {
                        HStack {
                            Text(settings.localized(level.localizedKey))
                                .font(.paceRounded(.body))
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            if level == selectedLevel {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(level == selectedLevel ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            
            Spacer()
        }
    }
}

// MARK: - Dashboard Rings

struct DashboardRingsView: View {
    let consumedCalories: Int
    let totalCalories: Int
    let consumedProtein: Int
    let totalProtein: Int
    let consumedFat: Int
    let totalFat: Int
    
    private static let ringLineWidth: CGFloat = 18
    private static let ringSpacing: CGFloat = 10
    private static let viewSize: CGFloat = 220
    
    private var progressCalories: CGFloat {
        guard totalCalories > 0 else { return 0 }
        return min(1, CGFloat(consumedCalories) / CGFloat(totalCalories))
    }
    
    private var progressProtein: CGFloat {
        guard totalProtein > 0 else { return 0 }
        return min(1, CGFloat(consumedProtein) / CGFloat(totalProtein))
    }
    
    private var progressFat: CGFloat {
        guard totalFat > 0 else { return 0 }
        return min(1, CGFloat(consumedFat) / CGFloat(totalFat))
    }
    
    // Brand colors (intentional design choice)
    private static let colorCalories = Color(red: 1, green: 0.267, blue: 0)
    private static let colorProtein = Color(red: 0.2, green: 0.68, blue: 0.38)
    private static let colorFat = Color(red: 0.996, green: 0.56, blue: 0.66)
    
    // Track color using system semantic color
    private static let trackColor = Color(.tertiarySystemFill)
    
    var body: some View {
        ZStack {
            ringView(progress: progressCalories, color: Self.colorCalories, radius: Self.ringRadius(for: 0))
            ringView(progress: progressProtein, color: Self.colorProtein, radius: Self.ringRadius(for: 1))
            ringView(progress: progressFat, color: Self.colorFat, radius: Self.ringRadius(for: 2))
        }
        .frame(width: Self.viewSize, height: Self.viewSize)
    }
    
    private static func ringRadius(for index: Int) -> CGFloat {
        let outer = (viewSize - ringLineWidth) / 2
        let step = ringLineWidth + ringSpacing
        return outer - CGFloat(index) * step
    }
    
    private func ringView(progress: CGFloat, color: Color, radius: CGFloat) -> some View {
        let size = radius * 2
        return ZStack {
            Circle()
                .stroke(Self.trackColor, style: StrokeStyle(lineWidth: Self.ringLineWidth, lineCap: .round))
                .frame(width: size, height: size)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: Self.ringLineWidth, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
        }
    }
}

#Preview {
    HomeView()
}
