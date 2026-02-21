//
//  PaceApp.swift
//  Pace
//
//  Created by Doltt on 2026/1/19.
//

import SwiftUI
import SwiftData

@main
struct PaceApp: App {
    @State private var showingAddFood = false
    @State private var settings = AppSettingsManager.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FoodEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView(externalShowAddFood: $showingAddFood)
                .preferredColorScheme(settings.theme.colorScheme)
                .environment(\.font, Font.system(.body, design: .rounded))
                .onOpenURL { url in
                    handleURL(url)
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func handleURL(_ url: URL) {
        // Handle pace://add-food from Live Activity
        guard url.scheme == "pace" else { return }
        
        if url.host == "add-food" {
            showingAddFood = true
        }
    }
}
