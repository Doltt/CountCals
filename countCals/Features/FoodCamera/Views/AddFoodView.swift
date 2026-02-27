//
//  AddFoodView.swift
//  Pace
//

import SwiftUI
import SwiftData

/// Entry point for adding food.
/// Per design spec: clicking "Add Food" directly enters the camera view.
struct AddFoodView: View {
    var onAddSuccess: (() -> Void)?
    
    init(onAddSuccess: (() -> Void)? = nil) {
        self.onAddSuccess = onAddSuccess
        print("[AddFoodView] ✅ Initialized")
    }
    
    var body: some View {
        print("[AddFoodView] 🎬 Creating FoodCameraView")
        return FoodCameraView(onAddSuccess: onAddSuccess)
    }
}

#Preview {
    AddFoodView()
        .modelContainer(for: FoodEntry.self, inMemory: true)
}
