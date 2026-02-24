//
//  DashboardBarsView.swift
//  Pace
//
//  Capsule bar chart matching reference design.
//

import SwiftUI

struct DashboardBarsView: View {
    let consumedCalories: Int
    let totalCalories: Int
    let consumedProtein: Int
    let totalProtein: Int
    let consumedCarbs: Int
    let totalCarbs: Int
    let consumedFat: Int
    let totalFat: Int
    
    private var settings: AppSettingsManager { AppSettingsManager.shared }
    
    // Reference image colors
    private static let colorCalories = Color(hex: "F05A28")  // Orange-Red
    private static let colorProtein = Color(hex: "4CAF50")   // Green
    private static let colorCarbs = Color(hex: "FFC107")     // Amber/Yellow
    private static let colorFat = Color(hex: "E91E63")       // Pink
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Bar 1: Calories - tallest
            CapsuleBar(
                value: consumedCalories,
                total: totalCalories,
                label: "Calories",
                color: Self.colorCalories,
                height: 320
            )
            
            // Bar 2: Protein - shorter
            CapsuleBar(
                value: consumedProtein,
                total: totalProtein,
                label: "Protein",
                color: Self.colorProtein,
                height: 270
            )
            .padding(.top, 50)
            
            // Bar 3: Carbs - shorter
            CapsuleBar(
                value: consumedCarbs,
                total: totalCarbs,
                label: "Carbs",
                color: Self.colorCarbs,
                height: 220
            )
            .padding(.top, 100)
            
            // Bar 4: Fat - shortest
            CapsuleBar(
                value: consumedFat,
                total: totalFat,
                label: "Fat",
                color: Self.colorFat,
                height: 170
            )
            .padding(.top, 150)
        }
        .padding(.horizontal, 20)
        .frame(height: 470)
    }
}

// MARK: - Capsule Bar

struct CapsuleBar: View {
    let value: Int
    let total: Int
    let label: String
    let color: Color
    let height: CGFloat
    
    private var settings: AppSettingsManager { AppSettingsManager.shared }
    
    private var progress: Double {
        total > 0 ? min(1.0, Double(value) / Double(total)) : 0
    }
    
    private var remaining: Int {
        max(0, total - value)
    }
    
    var body: some View {
        ZStack {
            // Background capsule (same color, low opacity)
            Capsule()
                .fill(color.opacity(0.2))
                .frame(width: 80, height: height)
            
            // Fill layer - from bottom, flat top, rounded bottom
            VStack(spacing: 0) {
                Spacer()
                
                // Fill rectangle with rounded bottom only
                RoundedRectangle(cornerRadius: 40)
                    .fill(color)
                    .frame(width: 80, height: height * progress)
                    .clipShape(BottomRoundedShape(cornerRadius: 40))
            }
            .frame(width: 80, height: height)
            .animation(.spring(response: 0.6, dampingFraction: 0.75), value: progress)
            
            // Content overlay
            VStack(spacing: 0) {
                // Top: Remaining amount
                if progress < 0.95 {
                    VStack(spacing: 2) {
                        Text("\(remaining)")
                            .font(.paceRounded(size: 16, weight: .bold))
                            .foregroundColor(color)
                        
                        Text("Remaining")
                            .font(.paceRounded(size: 9, weight: .medium))
                            .foregroundColor(color.opacity(0.8))
                    }
                    .padding(.top, 20)
                }
                
                Spacer()
                
                // Middle: Vertical label
                if progress < 0.85 {
                    Text(label)
                        .font(.paceRounded(size: 15, weight: .semibold))
                        .foregroundColor(color)
                        .rotationEffect(.degrees(-90))
                        .padding(.vertical, 10)
                }
                
                Spacer()
                
                // Bottom: Current value (inside fill)
                if progress > 0.15 {
                    VStack(spacing: 2) {
                        Text("\(value)")
                            .font(.paceRounded(size: 20, weight: .black))
                            .foregroundColor(.white)
                        
                        Text("/\(total)")
                            .font(.paceRounded(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.bottom, 20)
                }
            }
            .frame(width: 80, height: height)
        }
    }
}

// Shape that clips to rounded bottom only
struct BottomRoundedShape: Shape {
    let cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let radius = min(cornerRadius, rect.height / 2, rect.width / 2)
        
        // Start from top-left
        path.move(to: CGPoint(x: 0, y: 0))
        
        // Top edge (flat)
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        
        // Right edge down to start of bottom curve
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - radius))
        
        // Bottom-right corner
        path.addArc(
            center: CGPoint(x: rect.width - radius, y: rect.height - radius),
            radius: radius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        
        // Bottom edge
        path.addLine(to: CGPoint(x: radius, y: rect.height))
        
        // Bottom-left corner
        path.addArc(
            center: CGPoint(x: radius, y: rect.height - radius),
            radius: radius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )
        
        // Left edge up to top
        path.addLine(to: CGPoint(x: 0, y: 0))
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    DashboardBarsView(
        consumedCalories: 730,
        totalCalories: 2647,
        consumedProtein: 28,
        totalProtein: 165,
        consumedCarbs: 38,
        totalCarbs: 88,
        consumedFat: 38,
        totalFat: 88
    )
    .background(Color.black)
}
