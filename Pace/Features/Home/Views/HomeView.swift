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
                
                // Main visualization: Bars
                mainVisualization
                    .padding(.top, 40)
                    .scaleEffect(hasAppeared ? 1 : 0.8)
                    .opacity(hasAppeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: hasAppeared)
                
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
                    .font(.paceRounded(.caption))
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var mainVisualization: some View {
        Button {
            showingProfile = true
        } label: {
            DashboardBarsView(
                consumedCalories: consumedCalories,
                totalCalories: viewModel.dailyCalories,
                consumedProtein: viewModel.consumedProtein(from: allEntries),
                totalProtein: viewModel.dailyProtein,
                consumedCarbs: viewModel.consumedCarbs(from: allEntries),
                totalCarbs: viewModel.dailyCarbs,
                consumedFat: viewModel.consumedFat(from: allEntries),
                totalFat: viewModel.dailyFat
            )
        }
        .buttonStyle(.plain)
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
        NavigationStack {
            VStack(spacing: 0) {
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
            .navigationTitle(settings.localized(.activityLevel))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    HomeView()
}
