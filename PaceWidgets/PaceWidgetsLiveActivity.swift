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
                    MacroPill(icon: "circle.hexagonpath.fill", label: "C", value: state.remainingCarbs, color: Color(red: 1, green: 0.757, blue: 0.027)) // #FFC107
                    MacroPill(icon: "leaf.fill", label: "P", value: state.remainingProtein, color: Color(red: 0.298, green: 0.686, blue: 0.314)) // #4CAF50
                    MacroPill(icon: "drop.fill", label: "F", value: state.remainingFat, color: Color(red: 0.914, green: 0.118, blue: 0.388)) // #E91E63
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
    let icon: String
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(color)
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
