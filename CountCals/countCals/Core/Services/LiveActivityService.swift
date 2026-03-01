//
//  LiveActivityService.swift
//  Pace
//
//  Manages Live Activity lifecycle for lock screen widget.
//

import ActivityKit
import Foundation

/// Service to start, update, and end Live Activities.
final class LiveActivityService {
    
    static let shared = LiveActivityService()
    
    private var currentActivity: Activity<CountCalsAttributes>?
    
    private init() {}
    
    // MARK: - Public API
    
    /// Start a new Live Activity with the given nutrition data.
    func start(
        dailyTarget: Int,
        remainingCalories: Int,
        remainingCarbs: Int,
        remainingProtein: Int,
        remainingFat: Int
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("[LiveActivity] Activities not enabled")
            return
        }
        
        // End any existing activity first
        Task {
            await endAll()
            
            let attributes = CountCalsAttributes(dailyTarget: dailyTarget)
            let state = CountCalsAttributes.ContentState(
                remainingCalories: remainingCalories,
                remainingCarbs: remainingCarbs,
                remainingProtein: remainingProtein,
                remainingFat: remainingFat
            )
            
            do {
                let activity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: state, staleDate: nil),
                    pushType: nil
                )
                currentActivity = activity
                print("[LiveActivity] Started: \(activity.id)")
            } catch {
                print("[LiveActivity] Failed to start: \(error)")
            }
        }
    }
    
    /// Update the current Live Activity with new nutrition data.
    func update(
        remainingCalories: Int,
        remainingCarbs: Int,
        remainingProtein: Int,
        remainingFat: Int
    ) {
        guard let activity = currentActivity else {
            print("[LiveActivity] No active activity to update")
            return
        }
        
        let newState = CountCalsAttributes.ContentState(
            remainingCalories: remainingCalories,
            remainingCarbs: remainingCarbs,
            remainingProtein: remainingProtein,
            remainingFat: remainingFat
        )
        
        Task {
            await activity.update(.init(state: newState, staleDate: nil))
            print("[LiveActivity] Updated")
        }
    }
    
    /// End the current Live Activity.
    func end() {
        guard let activity = currentActivity else { return }
        
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
            print("[LiveActivity] Ended")
        }
    }
    
    /// End all Live Activities (cleanup).
    func endAll() async {
        for activity in Activity<CountCalsAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        currentActivity = nil
    }
    
    /// Check if there's an active Live Activity.
    var isActive: Bool {
        currentActivity != nil || !Activity<CountCalsAttributes>.activities.isEmpty
    }
}
