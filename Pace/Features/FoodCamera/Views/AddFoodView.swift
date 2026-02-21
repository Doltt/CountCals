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
    
    var body: some View {
        FoodCameraView(onAddSuccess: onAddSuccess)
    }
}

#Preview {
    AddFoodView()
        .modelContainer(for: FoodEntry.self, inMemory: true)
}
