//
//  ScanningOverlayView.swift
//  Pace
//

import SwiftUI

/// Radar-style scanning animation overlay.
/// Shows during AI processing phase to indicate analysis in progress.
struct ScanningOverlayView: View {
    let image: UIImage
    
    @State private var scanProgress: CGFloat = 0
    @State private var pulseOpacity: CGFloat = 0.5
    @State private var ringScales: [CGFloat] = [0, 0, 0]
    
    var body: some View {
        ZStack {
            // Background: captured image (dimmed)
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.6))
            
            // Scanning effect
            GeometryReader { geometry in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let maxRadius = max(geometry.size.width, geometry.size.height)
                
                ZStack {
                    // Expanding rings
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.orange.opacity(0.8),
                                        Color.pink.opacity(0.6),
                                        Color.purple.opacity(0.4)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .scaleEffect(ringScales[index])
                            .opacity(1 - Double(ringScales[index]))
                            .position(center)
                            .frame(width: maxRadius, height: maxRadius)
                    }
                    
                    // Center pulse
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(pulseOpacity),
                                    Color.orange.opacity(pulseOpacity * 0.5),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .position(center)
                    
                    // Scanning line (sweeping)
                    ScanLine(progress: scanProgress)
                        .stroke(
                            LinearGradient(
                                colors: [Color.clear, Color.white.opacity(0.8), Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            
            // Status text
            VStack {
                Spacer()
                
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                    
                    Text(AppSettingsManager.shared.localized(.analyzingFood))
                        .font(.paceRounded(.headline))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: Capsule())
                
                Spacer()
                    .frame(height: 100)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Scanning line animation
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            scanProgress = 1
        }
        
        // Pulse animation
        withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
            pulseOpacity = 0.8
        }
        
        // Staggered ring animations
        for i in 0..<3 {
            let delay = Double(i) * 0.6
            withAnimation(
                .easeOut(duration: 1.8)
                .repeatForever(autoreverses: false)
                .delay(delay)
            ) {
                ringScales[i] = 1.5
            }
        }
    }
}

// MARK: - Scan Line Shape

struct ScanLine: Shape {
    var progress: CGFloat
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let y = rect.height * progress
        path.move(to: CGPoint(x: 0, y: y))
        path.addLine(to: CGPoint(x: rect.width, y: y))
        return path
    }
}

// MARK: - Preview

#Preview {
    ScanningOverlayView(image: UIImage(systemName: "photo")!)
}
