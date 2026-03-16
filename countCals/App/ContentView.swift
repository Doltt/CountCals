//
//  ContentView.swift
//  Pace
//
//  Main container view with horizontal paging (swipe navigation).
//  Left: Settings | Center: Home Dashboard | Right: Daily Food Log
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Bindable private var settings = AppSettingsManager.shared
    @State private var selectedTab = 1
    @State private var showingAddFood = false
    @Binding var externalShowAddFood: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    init(externalShowAddFood: Binding<Bool> = .constant(false)) {
        _externalShowAddFood = externalShowAddFood
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Left: Settings
            SettingsView()
                .tag(0)
                .accessibilityLabel(AppSettingsManager.shared.localized(.settingsTab))
                .accessibilityAddTraits(selectedTab == 0 ? .isSelected : [])
            
            // Center: Home Dashboard
            HomeView(onAddFood: {
                showingAddFood = true
            })
            .tag(1)
            .accessibilityLabel(AppSettingsManager.shared.localized(.homeTab))
            .accessibilityAddTraits(selectedTab == 1 ? .isSelected : [])
            
            // Right: Daily Food Log
            DailyFoodLogView()
                .tag(2)
                .accessibilityLabel(AppSettingsManager.shared.localized(.dailyFoodLog))
                .accessibilityAddTraits(selectedTab == 2 ? .isSelected : [])
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .preferredColorScheme(settings.theme.colorScheme)
        
        .fullScreenCover(isPresented: $showingAddFood) {
            print("[ContentView] 🎯 Presenting AddFoodView")
            return AddFoodView(onAddSuccess: {
                print("[ContentView] ✅ AddFoodView completed, switching to Food Log")
                // After adding food, jump to Daily Food Log
                selectedTab = 2
            })
            .environment(\.font, Font.system(.body, design: .rounded))
        }
        .onChange(of: externalShowAddFood) { _, newValue in
            if newValue {
                showingAddFood = true
                externalShowAddFood = false
            }
        }
    }
}

#Preview {
    ContentView()
}
