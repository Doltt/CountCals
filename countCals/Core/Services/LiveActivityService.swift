//
//  LiveActivityService.swift
//  Pace
//
//  Manages Live Activity lifecycle for lock screen widget.
//

import ActivityKit
import Foundation

/// Service to start, update, and end Live Activities.
/// All mutations run on an actor to avoid concurrent start/update races that can surface as
/// ActivityKit errors (e.g. invalid handles after a failed or superseded request).
final class LiveActivityService {

    static let shared = LiveActivityService()

    private let coordinator = LiveActivityCoordinator()

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
        Task {
            await coordinator.start(
                dailyTarget: dailyTarget,
                remainingCalories: remainingCalories,
                remainingCarbs: remainingCarbs,
                remainingProtein: remainingProtein,
                remainingFat: remainingFat
            )
        }
    }

    /// Update the current Live Activity with new nutrition data.
    func update(
        remainingCalories: Int,
        remainingCarbs: Int,
        remainingProtein: Int,
        remainingFat: Int
    ) {
        Task {
            await coordinator.update(
                remainingCalories: remainingCalories,
                remainingCarbs: remainingCarbs,
                remainingProtein: remainingProtein,
                remainingFat: remainingFat
            )
        }
    }

    /// End the current Live Activity.
    func end() {
        Task {
            await coordinator.endCurrent()
        }
    }

    /// End all Live Activities (cleanup).
    func endAll() async {
        await coordinator.endAll()
    }

    /// True when at least one Live Activity for this attribute type is still active.
    var isActive: Bool {
        Activity<CountCalsAttributes>.activities.contains { $0.activityState == .active }
    }
}

// MARK: - Coordinator (serialized)

private actor LiveActivityCoordinator {

    private var currentActivity: Activity<CountCalsAttributes>?

    func start(
        dailyTarget: Int,
        remainingCalories: Int,
        remainingCarbs: Int,
        remainingProtein: Int,
        remainingFat: Int
    ) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("[LiveActivity] Activities not enabled")
            return
        }

        await endAllActivities()

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
            currentActivity = nil
            print("[LiveActivity] Failed to start: \(error)")
        }
    }

    func update(
        remainingCalories: Int,
        remainingCarbs: Int,
        remainingProtein: Int,
        remainingFat: Int
    ) async {
        guard let activity = resolveUpdatableActivity() else {
            print("[LiveActivity] No active activity to update")
            return
        }

        let newState = CountCalsAttributes.ContentState(
            remainingCalories: remainingCalories,
            remainingCarbs: remainingCarbs,
            remainingProtein: remainingProtein,
            remainingFat: remainingFat
        )

        await activity.update(.init(state: newState, staleDate: nil))
        print("[LiveActivity] Updated")
    }

    func endCurrent() async {
        if let activity = resolveUpdatableActivity() {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        currentActivity = nil
    }

    func endAll() async {
        await endAllActivities()
    }

    private func endAllActivities() async {
        for activity in Activity<CountCalsAttributes>.activities {
            switch activity.activityState {
            case .active, .stale:
                await activity.end(nil, dismissalPolicy: .immediate)
            case .ended, .dismissed:
                break
            @unknown default:
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        currentActivity = nil
    }

    /// Prefer cached reference if still active; otherwise adopt the first active system activity.
    private func resolveUpdatableActivity() -> Activity<CountCalsAttributes>? {
        if let cached = currentActivity, cached.activityState == .active {
            return cached
        }
        let active = Activity<CountCalsAttributes>.activities.first { $0.activityState == .active }
        currentActivity = active
        return active
    }
}
