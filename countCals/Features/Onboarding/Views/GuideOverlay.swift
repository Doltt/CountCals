//
//  GuideOverlay.swift
//  Pace
//
//  Feature guide overlay for first-time users.
//

import SwiftUI

struct GuideOverlay: View {
    @Binding var isShowing: Bool
    let highlightFrames: [GuideHighlightTarget: CGRect]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var currentTip: GuideTip = .rings
    @State private var currentHighlightFrame: CGRect = .zero
    
    enum GuideTip: CaseIterable {
        case rings
        case activity
        case addFood
        
        var title: String {
            let settings = AppSettingsManager.shared
            switch self {
            case .rings:
                return settings.language == .chinese ? "每日进度" : "Daily Progress"
            case .activity:
                return settings.language == .chinese ? "活动等级" : "Activity Level"
            case .addFood:
                return settings.language == .chinese ? "添加食物" : "Add Food"
            }
        }
        
        var message: String {
            let settings = AppSettingsManager.shared
            switch self {
            case .rings:
                return settings.language == .chinese 
                    ? "三环分别代表卡路里、蛋白质和脂肪的摄入进度"
                    : "Three rings track your calories, protein, and fat intake"
            case .activity:
                return settings.language == .chinese
                    ? "轻触切换活动等级，自动调整每日目标"
                    : "Tap to switch activity level and adjust daily goals"
            case .addFood:
                return settings.language == .chinese
                    ? "点击按钮，用 AI 拍照识别食物营养"
                    : "Tap to use AI camera to recognize food nutrition"
            }
        }
        
        var icon: String {
            switch self {
            case .rings: return "chart.ring.3rd"
            case .activity: return "figure.walk"
            case .addFood: return "camera.fill"
            }
        }
    }
    
    private var settings: AppSettingsManager { AppSettingsManager.shared }
    private var isLastTip: Bool { currentTip == GuideTip.allCases.last }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Dark overlay with cutout
                overlayShape(in: geo.size)
                    .ignoresSafeArea()
                
                // Tip bubble
                tipBubble(in: geo)
            }
            .onAppear {
                updateHighlightFrame()
            }
            .onChange(of: currentTip) { _, _ in
                updateHighlightFrame()
            }
        }
    }
    
    private func updateHighlightFrame() {
        let target: GuideHighlightTarget = {
            switch currentTip {
            case .rings: return .rings
            case .activity: return .activity
            case .addFood: return .addFood
            }
        }()
        
        if reduceMotion {
            currentHighlightFrame = highlightFrames[target] ?? .zero
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentHighlightFrame = highlightFrames[target] ?? .zero
            }
        }
    }
    
    // MARK: - Overlay Shape with Cutout
    
    private func overlayShape(in size: CGSize) -> some View {
        Canvas { context, size in
            // Fill entire screen with semi-transparent black
            let fullRect = CGRect(origin: .zero, size: size)
            context.fill(Path(fullRect), with: .color(Color.black.opacity(0.75)))
            
            // Cut out the highlighted area
            if currentHighlightFrame != .zero {
                let cutoutRect = currentHighlightFrame.insetBy(dx: -8, dy: -8)
                let cutoutPath = Path(roundedRect: cutoutRect, cornerRadius: 16)
                context.blendMode = .clear
                context.fill(cutoutPath, with: .color(.black))
                context.blendMode = .normal
                
                // Add subtle glow around cutout
                var glowPath = Path(roundedRect: cutoutRect, cornerRadius: 16)
                glowPath = glowPath.strokedPath(StrokeStyle(lineWidth: 2))
                context.stroke(glowPath, with: .color(Color(red: 1, green: 0.267, blue: 0).opacity(0.5)), lineWidth: 2)
            }
        }
    }
    
    // MARK: - Tip Bubble
    
    private func tipBubble(in geo: GeometryProxy) -> some View {
        let bubblePosition = calculateBubblePosition(in: geo)
        
        return VStack(spacing: 0) {
            // Arrow pointing to highlight
            if bubblePosition.showAbove {
                Spacer()
                    .frame(height: bubblePosition.arrowY)
                arrow(isPointingUp: false)
            } else {
                Spacer()
                    .frame(height: bubblePosition.arrowY - 12)
                arrow(isPointingUp: true)
            }
            
            // Bubble content
            VStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(red: 1, green: 0.267, blue: 0).opacity(0.2))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: currentTip.icon)
                        .font(.paceRounded(size: 24, weight: .semibold))
                        .foregroundColor(Color(red: 1, green: 0.267, blue: 0))
                }
                
                // Title
                Text(currentTip.title)
                    .font(.paceRounded(size: 20, weight: .bold))
                    .foregroundColor(Color(red: 0.996, green: 0.976, blue: 0.937))
                
                // Message
                Text(currentTip.message)
                    .font(.paceRounded(size: 15, weight: .medium))
                    .foregroundColor(Color(red: 0.996, green: 0.976, blue: 0.937).opacity(0.7))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(Array(GuideTip.allCases.enumerated()), id: \.element) { index, tip in
                        Circle()
                            .fill(tip == currentTip ? Color(red: 1, green: 0.267, blue: 0) : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(reduceMotion ? nil : .spring(response: 0.3), value: currentTip)
                    }
                }
                .padding(.top, 8)
                
                // Button
                Button(action: nextTip) {
                    Text(isLastTip 
                         ? (settings.language == .chinese ? "开始探索" : "Start Exploring")
                         : (settings.language == .chinese ? "下一步" : "Next"))
                        .font(.paceRounded(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            Capsule()
                                .fill(Color(red: 1, green: 0.267, blue: 0))
                        )
                }
                .accessibilityLabel(isLastTip
                    ? (settings.language == .chinese ? "开始探索" : "Start Exploring")
                    : (settings.language == .chinese ? "下一步" : "Next"))
                .accessibilityHint(isLastTip
                    ? (settings.language == .chinese ? "双击关闭引导" : "Double tap to close guide")
                    : (settings.language == .chinese ? "双击进入下一步" : "Double tap for next step"))
                .padding(.top, 8)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .frame(maxWidth: 320)
            
            if !bubblePosition.showAbove {
                Spacer()
            }
        }
        .position(x: geo.size.width / 2, y: geo.size.height / 2)
    }
    
    private func arrow(isPointingUp: Bool) -> some View {
        Image(systemName: isPointingUp ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
            .font(.system(size: 16))
            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
            .offset(y: isPointingUp ? 6 : -6)
    }
    
    private func calculateBubblePosition(in geo: GeometryProxy) -> (arrowY: CGFloat, showAbove: Bool) {
        let screenHeight = geo.size.height
        let highlightCenterY = currentHighlightFrame.midY
        let bubbleHeight: CGFloat = 280
        
        // Show above highlight if there's enough space, otherwise below
        let spaceAbove = highlightCenterY - currentHighlightFrame.height / 2 - 20
        let spaceBelow = screenHeight - highlightCenterY - currentHighlightFrame.height / 2 - 20
        
        let showAbove = spaceBelow < bubbleHeight && spaceAbove > spaceBelow
        
        if showAbove {
            return (highlightCenterY - currentHighlightFrame.height / 2 - 20, true)
        } else {
            return (highlightCenterY + currentHighlightFrame.height / 2 + 20, false)
        }
    }
    
    private func nextTip() {
        if let currentIndex = GuideTip.allCases.firstIndex(of: currentTip),
           currentIndex < GuideTip.allCases.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentTip = GuideTip.allCases[currentIndex + 1]
            }
        } else {
            withAnimation {
                isShowing = false
                GuideManager.shared.markGuideAsSeen()
            }
        }
    }
}

// MARK: - Preference Key for Highlight Frames

struct GuideHighlightPreferenceKey: PreferenceKey {
    static var defaultValue: [GuideHighlightTarget: CGRect] = [:]
    
    static func reduce(value: inout [GuideHighlightTarget: CGRect], nextValue: () -> [GuideHighlightTarget: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

enum GuideHighlightTarget: String, CaseIterable {
    case rings
    case activity
    case addFood
}

// MARK: - View Modifier

struct GuideHighlightModifier: ViewModifier {
    let target: GuideHighlightTarget
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: GuideHighlightPreferenceKey.self,
                            value: [target: geo.frame(in: .global)]
                        )
                }
            )
    }
}

extension View {
    func guideHighlight(_ target: GuideHighlightTarget) -> some View {
        modifier(GuideHighlightModifier(target: target))
    }
}

// MARK: - Guide Manager

@Observable
final class GuideManager {
    static let shared = GuideManager()
    
    var shouldShowGuide: Bool {
        get { !UserDefaults.standard.bool(forKey: "hasSeenFeatureGuide") }
        set { UserDefaults.standard.set(!newValue, forKey: "hasSeenFeatureGuide") }
    }
    
    func markGuideAsSeen() {
        UserDefaults.standard.set(true, forKey: "hasSeenFeatureGuide")
    }
    
    func resetGuide() {
        UserDefaults.standard.set(false, forKey: "hasSeenFeatureGuide")
    }
}

// MARK: - Guide Overlay Container

struct GuideOverlayContainer: View {
    @Binding var isShowing: Bool
    let highlightFrames: [GuideHighlightTarget: CGRect]
    
    var body: some View {
        if isShowing {
            GuideOverlay(isShowing: $isShowing, highlightFrames: highlightFrames)
        }
    }
}

#Preview {
    GuideOverlay(
        isShowing: .constant(true),
        highlightFrames: [.rings: CGRect(x: 100, y: 200, width: 200, height: 200)]
    )
}
