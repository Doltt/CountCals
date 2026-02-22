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
            
            // Center: Home Dashboard
            HomeView(onAddFood: {
                showingAddFood = true
            })
            .tag(1)
            
            // Right: Daily Food Log
            DailyFoodLogView()
                .tag(2)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .ignoresSafeArea(edges: [.top, .bottom])
        .fullScreenCover(isPresented: $showingAddFood) {
            AddFoodView(onAddSuccess: {
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
