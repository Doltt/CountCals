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
    @State private var tab2HasPushedView = false
    @State private var triggerPopInTab2 = false
    
    init(externalShowAddFood: Binding<Bool> = .constant(false)) {
        _externalShowAddFood = externalShowAddFood
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SettingsView()
                .tag(0)
            HomeView(onAddFood: { showingAddFood = true })
                .tag(1)
            DailyFoodLogView(
                hasPushedView: $tab2HasPushedView,
                triggerPop: $triggerPopInTab2
            )
                .tag(2)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .overlay {
            if selectedTab == 2, tab2HasPushedView {
                HStack(spacing: 0) {
                    Color.clear
                        .frame(width: 50)
                        .allowsHitTesting(false)
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity)
                        .highPriorityGesture(
                            DragGesture(minimumDistance: 20)
                                .onEnded { value in
                                    if value.translation.width > 80 {
                                        triggerPopInTab2 = true
                                    }
                                }
                        )
                }
            }
        }
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
