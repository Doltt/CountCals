//
//  PaceActivityAttributes.swift
//  Pace
//
//  Shared ActivityAttributes for Live Activity.
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
