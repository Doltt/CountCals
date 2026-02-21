//
//  ContentView.swift
//  Pace
//
//  Main container view with TabView navigation and floating add food button.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingAddFood = false
    @State private var settings = AppSettingsManager.shared
    @Binding var externalShowAddFood: Bool
    
    init(externalShowAddFood: Binding<Bool> = .constant(false)) {
        _externalShowAddFood = externalShowAddFood
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: - TabView
            TabView(selection: $selectedTab) {
                // Home Tab
                HomeView()
                    .tabItem {
                        Label(settings.localized(.homeTab), systemImage: "house.fill")
                    }
                    .tag(0)
                
                // Settings Tab
                SettingsView()
                    .tabItem {
                        Label(settings.localized(.settingsTab), systemImage: "gearshape.fill")
                    }
                    .tag(1)
            }
            
            // MARK: - Floating Add Food Button
            floatingAddFoodButton
                .padding(.bottom, 12)
        }
        .ignoresSafeArea(edges: .bottom)
        .fullScreenCover(isPresented: $showingAddFood) {
            AddFoodView(onAddSuccess: {
                selectedTab = 0
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
    
    // MARK: - Floating Add Food Button
    private var floatingAddFoodButton: some View {
        HStack {
            Spacer()
            
            Button {
                showingAddFood = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.paceRounded(.subheadline, weight: .semibold))
                    Text(settings.localized(.addFood))
                        .font(.paceRounded(.subheadline, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color(red: 1, green: 0.267, blue: 0))
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(.plain)
            .padding(.trailing, 20)
        }
    }
}

#Preview {
    ContentView()
}
