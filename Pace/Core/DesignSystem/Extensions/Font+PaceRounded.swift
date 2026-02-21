//
//  Font+PaceRounded.swift
//  Pace
//
//  全局优先使用 SF Pro Rounded。
//

import SwiftUI

extension Font {
    /// SF Pro Rounded - 语义样式（跟随 Dynamic Type）
    static func paceRounded(_ style: Font.TextStyle, weight: Font.Weight = .heavy) -> Font {
        .system(style, design: .rounded).weight(weight)
    }

    /// SF Pro Rounded - 固定字号
    static func paceRounded(size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
