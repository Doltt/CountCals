//
//  PaceWidgetsLiveActivity.swift
//  PaceWidgets
//
//  Created by Doltt on 2026/1/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Live Activity Widget

struct PaceWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PaceWidgetsAttributes.self) { context in
            // Lock screen UI
            LockScreenView(
                state: context.state,
                dailyTarget: context.attributes.dailyTarget
            )
            .activityBackgroundTint(Color.black.opacity(0.75))
            
        } dynamicIsland: { _ in
            // Dynamic Island disabled - only show on lock screen
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { EmptyView() }
                DynamicIslandExpandedRegion(.trailing) { EmptyView() }
                DynamicIslandExpandedRegion(.bottom) { EmptyView() }
            } compactLeading: {
                EmptyView()
            } compactTrailing: {
                EmptyView()
            } minimal: {
                EmptyView()
            }
        }
    }
}

// MARK: - Lock Screen View

private struct LockScreenView: View {
    let state: PaceWidgetsAttributes.ContentState
    let dailyTarget: Int
    
    var body: some View {
        HStack(alignment: .center) {
            // Left: Main content
            VStack(alignment: .leading, spacing: 6) {
                // Title
                Text("Remaining")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                
                // Large calorie number
                Text("\(state.remainingCalories)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(state.remainingCalories >= 0 ? Color.primary : Color.red)
                    .contentTransition(.numericText())
                
                // Macros row
                HStack(spacing: 12) {
                    MacroPill(emoji: "🥖", label: "C", value: state.remainingCarbs)
                    MacroPill(emoji: "🥩", label: "P", value: state.remainingProtein)
                    MacroPill(emoji: "🥑", label: "F", value: state.remainingFat)
                }
            }
            
            Spacer()
            
            // Right: Add button (styled like Break Time's "End" button)
            Link(destination: URL(string: "pace://add-food")!) {
                Text("Add")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: - Helper Views

private struct MacroPill: View {
    let emoji: String
    let label: String
    let value: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: 12, design: .rounded))
            Text("\(value)")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Preview Helpers

extension PaceWidgetsAttributes {
    fileprivate static var preview: PaceWidgetsAttributes {
        PaceWidgetsAttributes(dailyTarget: 2200)
    }
}

extension PaceWidgetsAttributes.ContentState {
    fileprivate static var normal: PaceWidgetsAttributes.ContentState {
        PaceWidgetsAttributes.ContentState(
            remainingCalories: 1450,
            remainingCarbs: 180,
            remainingProtein: 85,
            remainingFat: 55
        )
    }
    
    fileprivate static var low: PaceWidgetsAttributes.ContentState {
        PaceWidgetsAttributes.ContentState(
            remainingCalories: 320,
            remainingCarbs: 40,
            remainingProtein: 20,
            remainingFat: 10
        )
    }
}

#Preview("Notification", as: .content, using: PaceWidgetsAttributes.preview) {
    PaceWidgetsLiveActivity()
} contentStates: {
    PaceWidgetsAttributes.ContentState.normal
    PaceWidgetsAttributes.ContentState.low
}
