//
//  StickerImageView.swift
//  Pace
//
//  Shared sticker-style cutout image with optional white outline.
//  Used by FoodCamera result and Food Detail for consistent app language.
//

import SwiftUI
import UIKit

/// Displays a cutout image with sticker-style white border.
/// Uses pre-generated outline for high-quality edge, or fallback when nil.
struct StickerImageView: View {
    let cutoutImage: UIImage
    let outlineImage: UIImage?
    var maxWidth: CGFloat = 600
    var maxHeight: CGFloat = 700
    
    var body: some View {
        ZStack {
            if let outline = outlineImage {
                Image(uiImage: outline)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: maxWidth, maxHeight: maxHeight)
            } else {
                Image(uiImage: cutoutImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: maxWidth, maxHeight: maxHeight)
                    .colorMultiply(.white)
                    .blur(radius: 3)
                    .scaleEffect(1.04)
            }
            Image(uiImage: cutoutImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: maxWidth, maxHeight: maxHeight)
        }
        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
    }
}
