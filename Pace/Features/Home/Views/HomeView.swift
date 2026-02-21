//
//  HomeView.swift
//  Pace
//
//  Home dashboard with rings visualization and activity level selector.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var allEntries: [FoodEntry]
    @State private var viewModel = DashboardViewModel()
    @State private var showingActivityPicker = false
    @State private var showingProfile = false
    @Environment(\.colorScheme) private var colorScheme
    private var settings: AppSettingsManager { AppSettingsManager.shared }

    // MARK: - Launch Animation State
    @State private var hasAppeared = false
    
    init() {
        _allEntries = Query(sort: \FoodEntry.timestamp, order: .reverse)
    }
    
    private var consumedCalories: Int {
        viewModel.consumedCalories(from: allEntries)
    }
    
    var body: some View {
        ZStack {
            dashboardBgColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header: Activity Level selector
                activityLevelHeader
                    .padding(.top, 60)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : -20)
                    .animation(.easeOut(duration: 0.4).delay(0.1), value: hasAppeared)
                
                // Main visualization: Rings + Stats
                mainVisualization
                    .padding(.top, 40)
                    .scaleEffect(hasAppeared ? 1 : 0.8)
                    .opacity(hasAppeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: hasAppeared)
                
                Spacer()
            }
        }
        .onAppear {
            guard !hasAppeared else { return }
            DispatchQueue.main.async {
                hasAppeared = true
            }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView(viewModel: viewModel)
                .environment(\.font, Font.system(.body, design: .rounded))
        }
        .sheet(isPresented: $showingActivityPicker) {
            ActivityLevelSheet(
                selectedLevel: viewModel.activityLevel,
                onSelect: { level in
                    viewModel.updateActivityLevel(level)
                }
            )
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(.clear)
        }
    }
    
    // MARK: - Colors
    
    private var dashboardBgColor: Color {
        colorScheme == .dark
            ? Color(red: 0.02, green: 0.02, blue: 0.02)
            : Color(red: 0.98, green: 0.98, blue: 0.98)
    }
    private var dashboardTextColor: Color {
        colorScheme == .dark
            ? Color(red: 0.996, green: 0.976, blue: 0.937)
            : Color(red: 0.1, green: 0.1, blue: 0.1)
    }
    private var dashboardTextSecondary: Color {
        colorScheme == .dark
            ? Color(red: 0.996, green: 0.976, blue: 0.937).opacity(0.3)
            : Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.5)
    }
    
    // MARK: - Subviews
    
    private var activityLevelHeader: some View {
        Button {
            showingActivityPicker = true
        } label: {
            VStack(spacing: 10) {
                Text(settings.localized(viewModel.activityLevel.localizedKey))
                    .font(.paceRounded(size: 40))
                    .foregroundColor(dashboardTextColor)
                    .contentTransition(.numericText())

                Text(settings.localized(.activityLevel))
                    .font(.paceRounded(size: 14))
                    .foregroundColor(dashboardTextSecondary)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var mainVisualization: some View {
        VStack(spacing: 0) {
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
            
            Text(settings.localized(.remainingToday))
                .font(.paceRounded(size: 14))
                .foregroundColor(dashboardTextSecondary)
                .padding(.top, 12)
            
            statsRow
                .padding(.top, 10)
        }
    }
    
    private var statsRow: some View {
        let remainingCal = max(0, viewModel.dailyCalories - consumedCalories)
        let remainingProtein = max(0, viewModel.dailyProtein - viewModel.consumedProtein(from: allEntries))
        let remainingFat = max(0, viewModel.dailyFat - viewModel.consumedFat(from: allEntries))
        
        return HStack(spacing: 20) {
            statItem(icon: "flame.fill", value: "\(remainingCal)Cal", color: Color(red: 1, green: 0.267, blue: 0))
            statItem(icon: "leaf.fill", value: "\(remainingProtein)g", color: Color(red: 0.2, green: 0.68, blue: 0.38))
            statItem(icon: "drop.fill", value: "\(remainingFat)g", color: Color(red: 0.996, green: 0.56, blue: 0.66))
        }
    }
    
    private func statItem(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.paceRounded(size: 18))
                .foregroundColor(color)
            Text(value)
                .font(.paceRounded(size: 14))
                .foregroundColor(dashboardTextColor)
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
    
    private static let ringLineWidth: CGFloat = 12
    private static let ringSpacing: CGFloat = 8
    private static let viewSize: CGFloat = 200
    
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
    
    private static let colorCalories = Color(red: 1, green: 0.267, blue: 0)
    private static let colorProtein = Color(red: 0.2, green: 0.68, blue: 0.38)
    private static let colorFat = Color(red: 0.996, green: 0.56, blue: 0.66)
    private static let trackColor = Color.white.opacity(0.1)
    
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

// MARK: - Activity Level Sheet

struct ActivityLevelSheet: View {
    let selectedLevel: UserProfile.ActivityLevel
    let onSelect: (UserProfile.ActivityLevel) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 20)

            Text(AppSettingsManager.shared.localized(.activityLevel))
                .font(.paceRounded(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 24)

            VStack(spacing: 12) {
                ForEach(UserProfile.ActivityLevel.allCases, id: \.self) { level in
                    Button {
                        onSelect(level)
                        dismiss()
                    } label: {
                        HStack {
                            Text(AppSettingsManager.shared.localized(level.localizedKey))
                                .font(.paceRounded(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                            if level == selectedLevel {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.paceRounded(size: 20))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.08))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text(AppSettingsManager.shared.localized(.complete))
                    .font(.paceRounded(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color(red: 0.9, green: 0.5, blue: 0.4))
                    )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 34)
        }
        .background(
            ZStack {
                Color.black.opacity(0.7)
                LinearGradient(
                    colors: [
                        Color.orange.opacity(0.15),
                        Color.green.opacity(0.1),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .ignoresSafeArea()
        )
    }
}
