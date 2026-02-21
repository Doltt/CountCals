//
//  FoodStickerResultView.swift
//  Pace
//

import SwiftUI

/// Sticker card result view showing recognized food with nutrition info.
/// Handles all recognition states with humor and delightful UX.
struct FoodStickerResultView: View {
    let result: FoodRecognitionResult
    let onRetake: () -> Void
    let onConfirm: () -> Void
    let onCancel: () -> Void
    let onEdit: () -> Void
    var onRetry: (() -> Void)? = nil

    @State private var stickerScale: CGFloat = 0.5
    @State private var stickerOpacity: CGFloat = 0
    @State private var badgeScale: CGFloat = 0
    @State private var cardOffset: CGFloat = 300
    @State private var cardOpacity: CGFloat = 0
    @State private var buttonsOpacity: CGFloat = 0
    @State private var showingSaveSuccess = false
    @State private var showingSaveError = false
    
    private var status: RecognitionStatus { result.status }
    private var isNonStandardResult: Bool { status != .success }

    var body: some View {
        ZStack {
            // Dotted paper background
            DottedPaperBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top navigation
                topBar

                Spacer()

                // Sticker image with badge overlay
                ZStack(alignment: .topTrailing) {
                    stickerImageView
                        .scaleEffect(stickerScale)
                        .opacity(stickerOpacity)
                        .onLongPressGesture {
                            saveStickerToPhotos()
                        }
                    
                    // Status badge (emoji)
                    if !status.badge.isEmpty {
                        Text(status.badge)
                            .font(.paceRounded(size: 44))
                            .scaleEffect(badgeScale)
                            .offset(x: 20, y: -20)
                    }
                }
                .frame(minHeight: stickerMaxHeight * 0.8)
                .layoutPriority(1)
                .sensoryFeedback(.success, trigger: showingSaveSuccess)
                .alert(AppSettingsManager.shared.localized(.saved), isPresented: $showingSaveSuccess) {
                    Button(AppSettingsManager.shared.localized(.ok)) {}
                } message: {
                    Text(AppSettingsManager.shared.localized(.stickerSaved))
                }
                .alert(AppSettingsManager.shared.localized(.saveFailed), isPresented: $showingSaveError) {
                    Button(AppSettingsManager.shared.localized(.ok)) {}
                } message: {
                    Text(AppSettingsManager.shared.localized(.allowPhotoAccess))
                }

                Spacer()
                    .frame(height: 24)

                // Nutrition card (or status card for non-food)
                resultCard
                    .offset(y: cardOffset)
                    .opacity(cardOpacity)

                Spacer()
                    .frame(height: 24)

                // Action buttons
                actionButtons
                    .opacity(buttonsOpacity)

                Spacer()
                    .frame(height: 40)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            animateIn()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                onCancel()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.paceRounded(.title2))
                    .foregroundStyle(.primary)
            }

            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }

    // MARK: - Sticker Image

    // Dynamic sticker size based on screen width (85% of screen width, max 500pt)
    private var stickerMaxWidth: CGFloat {
        min(UIScreen.main.bounds.width * 0.85, 500)
    }
    private var stickerMaxHeight: CGFloat {
        stickerMaxWidth * 1.2
    }
    
    @ViewBuilder
    private var stickerImageView: some View {
        if let cutout = result.cutoutImage {
            // Use high-quality sticker view with pre-generated outline
            StickerImageView(
                cutoutImage: cutout,
                outlineImage: result.outlineImage,
                maxWidth: stickerMaxWidth,
                maxHeight: stickerMaxHeight
            )
        } else {
            // Fallback to original image with rounded corners
            Image(uiImage: result.originalImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: stickerMaxWidth, maxHeight: stickerMaxHeight)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
        }
    }

    // MARK: - Result Card
    
    @ViewBuilder
    private var resultCard: some View {
        if isNonStandardResult {
            statusCard
        } else {
            nutritionCard
        }
    }
    
    // MARK: - Status Card (for non-standard results)
    
    private var statusCard: some View {
        VStack(spacing: 16) {
            // Headline
            Text(status.headline)
                .font(.paceRounded(.title2, weight: .black))
                .foregroundStyle(status.accentColor)
            
            // Witty subtitle
            Text(status.subtitle)
                .font(.paceRounded(.subheadline))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            // Show nutrition if available (user might still want to confirm)
            if result.calories > 0 {
                Divider()
                    .padding(.vertical, 4)
                
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(result.calories)")
                        .font(.paceRounded(size: 32, weight: .black))
                        .foregroundStyle(status.accentColor)
                    Text("Cal")
                        .font(.paceRounded(.subheadline))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 28)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 15, y: 8)
        )
    }

    // MARK: - Nutrition Card (for successful recognition)

    private var nutritionCard: some View {
        VStack(spacing: 12) {
            // Food name
            Text(result.name)
                .font(.paceRounded(.title3, weight: .black))
                .foregroundStyle(.primary)

            // Calories (big number)
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(result.calories)")
                    .font(.paceRounded(size: 42, weight: .black))
                Text("Cal")
                    .font(.paceRounded(.headline))
                    .foregroundStyle(.secondary)
            }

            // Macros row
            HStack(spacing: 20) {
                MacroItem(label: AppSettingsManager.shared.localized(.carbsLabel), value: result.carbs, unit: "g", color: .orange)
                MacroItem(label: AppSettingsManager.shared.localized(.proteinLabel), value: result.protein, unit: "g", color: .blue)
                MacroItem(label: AppSettingsManager.shared.localized(.fatLabel), value: result.fat, unit: "g", color: .purple)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 28)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 15, y: 8)
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Primary action depends on status
            if status.canRetry, let retry = onRetry {
                // Retry button for network/timeout errors
                Button {
                    retry()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text(AppSettingsManager.shared.localized(.tryAgain))
                    }
                    .font(.paceRounded(.headline, weight: .black))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [status.accentColor, status.accentColor.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .foregroundStyle(.white)
                }
            } else if isNonStandardResult {
                // Edit button highlighted for non-standard results
                Button {
                    onEdit()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil")
                        Text(AppSettingsManager.shared.localized(.fillInDetails))
                    }
                    .font(.paceRounded(.headline, weight: .black))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [status.accentColor, status.accentColor.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .foregroundStyle(.white)
                }
            } else {
                // Normal confirm button
                Button {
                    onConfirm()
                } label: {
                    Text(AppSettingsManager.shared.localized(.confirm))
                        .font(.paceRounded(.headline, weight: .black))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.orange, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .foregroundStyle(.white)
                }
            }

            // Secondary row
            HStack(spacing: 12) {
                Button {
                    onRetake()
                } label: {
                    Text(AppSettingsManager.shared.localized(.retake))
                        .font(.paceRounded(.subheadline))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.primary)
                }

                if isNonStandardResult && !status.canRetry {
                    // Show Confirm as secondary for non-standard (user can still add)
                    Button {
                        onConfirm()
                    } label: {
                        Text(AppSettingsManager.shared.localized(.addAnyway))
                            .font(.paceRounded(.subheadline))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.primary)
                    }
                } else {
                    Button {
                        onEdit()
                    } label: {
                        Text(AppSettingsManager.shared.localized(.edit))
                            .font(.paceRounded(.subheadline))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
    }

    // MARK: - Animations

    // MARK: - Save Sticker to Photos

    private func saveStickerToPhotos() {
        guard let cutout = result.cutoutImage else { return }
        
        // Render sticker view to PNG with transparent background
        let stickerView = StickerImageView(
            cutoutImage: cutout,
            outlineImage: result.outlineImage,
            maxWidth: 680,
            maxHeight: 800
        )
        
        let renderer = ImageRenderer(content: stickerView)
        renderer.scale = UIScreen.main.scale
        renderer.isOpaque = false  // Enable transparency
        
        // Get CGImage and convert to PNG data to preserve alpha channel
        guard let cgImage = renderer.cgImage,
              let pngData = UIImage(cgImage: cgImage).pngData(),
              let pngImage = UIImage(data: pngData) else {
            showingSaveError = true
            return
        }
        
        // Save PNG to photo library
        let imageSaver = ImageSaver { success in
            if success {
                showingSaveSuccess = true
            } else {
                showingSaveError = true
            }
        }
        imageSaver.saveToPhotoAlbum(image: pngImage)
    }

    private func animateIn() {
        // Sticker bounce in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.1)) {
            stickerScale = 1
            stickerOpacity = 1
        }
        
        // Badge pop in (after sticker)
        if !status.badge.isEmpty {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.35)) {
                badgeScale = 1
            }
        }

        // Card slide up
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.25)) {
            cardOffset = 0
            cardOpacity = 1
        }

        // Buttons fade in
        withAnimation(.easeOut(duration: 0.3).delay(0.4)) {
            buttonsOpacity = 1
        }
    }
}

// MARK: - Dotted Paper Background

struct DottedPaperBackground: View {
    let dotSize: CGFloat = 2
    let dotSpacing: CGFloat = 20

    var body: some View {
        GeometryReader { geometry in
            let columns = Int(geometry.size.width / dotSpacing) + 1
            let rows = Int(geometry.size.height / dotSpacing) + 1

            ZStack {
                // Base paper color
                Color(.systemBackground)

                // Dots pattern
                Canvas { context, size in
                    for row in 0..<rows {
                        for col in 0..<columns {
                            let x = CGFloat(col) * dotSpacing + dotSpacing / 2
                            let y = CGFloat(row) * dotSpacing + dotSpacing / 2

                            // Random color for variety
                            let colors: [Color] = [
                                .gray.opacity(0.2),
                                .blue.opacity(0.15),
                                .purple.opacity(0.15),
                                .orange.opacity(0.15),
                                .green.opacity(0.15)
                            ]
                            let colorIndex = (row * columns + col) % colors.count

                            context.fill(
                                Path(ellipseIn: CGRect(
                                    x: x - dotSize / 2,
                                    y: y - dotSize / 2,
                                    width: dotSize,
                                    height: dotSize
                                )),
                                with: .color(colors[colorIndex])
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Macro Item

struct MacroItem: View {
    let label: String
    let value: Int
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text("\(value)")
                    .font(.paceRounded(.title3))
                Text(unit)
                    .font(.paceRounded(.caption))
                    .foregroundStyle(.secondary)
            }
            
            Text(label)
                .font(.paceRounded(.caption))
                .foregroundStyle(.secondary)
            
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 40, height: 4)
        }
    }
}

// MARK: - Edit Sheet View

struct FoodEditSheet: View {
    @Binding var name: String
    @Binding var calories: String
    @Binding var carbs: String
    @Binding var protein: String
    @Binding var fat: String
    let onSave: () -> Void
    let onCancel: () -> Void
    private var settings: AppSettingsManager { AppSettingsManager.shared }

    var body: some View {
        NavigationStack {
            Form {
                Section(settings.localized(.foodInfo)) {
                    TextField(settings.localized(.name), text: $name)
                    TextField(settings.localized(.calories), text: $calories)
                        .keyboardType(.numberPad)
                }

                Section(settings.localized(.macrosGrams)) {
                    TextField(settings.localized(.carbsLabel), text: $carbs)
                        .keyboardType(.numberPad)
                    TextField(settings.localized(.proteinLabel), text: $protein)
                        .keyboardType(.numberPad)
                    TextField(settings.localized(.fatLabel), text: $fat)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle(settings.localized(.editFood))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(settings.localized(.cancel)) { onCancel() }
                        .font(.paceRounded(.body))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(settings.localized(.save)) { onSave() }
                        .font(.paceRounded(.body))
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Success") {
    FoodStickerResultView(
        result: FoodRecognitionResult(
            name: "Coffee",
            calories: 5,
            carbs: 1,
            protein: 0,
            fat: 0,
            originalImage: UIImage(systemName: "cup.and.saucer.fill")!,
            cutoutImage: nil,
            outlineImage: nil,
            status: .success
        ),
        onRetake: {},
        onConfirm: {},
        onCancel: {},
        onEdit: {}
    )
}

#Preview("Mystery Item") {
    FoodStickerResultView(
        result: FoodRecognitionResult(
            name: "Unknown Food",
            calories: 0,
            carbs: 0,
            protein: 0,
            fat: 0,
            originalImage: UIImage(systemName: "questionmark.circle.fill")!,
            cutoutImage: nil,
            outlineImage: nil,
            status: .mystery
        ),
        onRetake: {},
        onConfirm: {},
        onCancel: {},
        onEdit: {}
    )
}

#Preview("Not Food") {
    FoodStickerResultView(
        result: FoodRecognitionResult(
            name: "Object",
            calories: 0,
            carbs: 0,
            protein: 0,
            fat: 0,
            originalImage: UIImage(systemName: "cube.fill")!,
            cutoutImage: nil,
            outlineImage: nil,
            status: .notFood
        ),
        onRetake: {},
        onConfirm: {},
        onCancel: {},
        onEdit: {}
    )
}

#Preview("Network Error") {
    FoodStickerResultView(
        result: FoodRecognitionResult(
            name: "Unknown Food",
            calories: 0,
            carbs: 0,
            protein: 0,
            fat: 0,
            originalImage: UIImage(systemName: "wifi.slash")!,
            cutoutImage: nil,
            outlineImage: nil,
            status: .networkError
        ),
        onRetake: {},
        onConfirm: {},
        onCancel: {},
        onEdit: {},
        onRetry: { print("Retry tapped") }
    )
}
