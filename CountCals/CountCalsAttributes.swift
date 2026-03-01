//
//  PaceActivityAttributes.swift
//  Pace & PaceWidgets
//
//  Shared ActivityAttributes for Live Activity.
//  This file should be added to BOTH Pace and PaceWidgetsExtension targets.
//

import ActivityKit
import Foundation

struct CountCalsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingCalories: Int
        var remainingCarbs: Int
        var remainingProtein: Int
        var remainingFat: Int
    }
    
    var dailyTarget: Int
}
