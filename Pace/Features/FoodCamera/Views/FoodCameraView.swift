//
//  FoodCameraView.swift
//  Pace
//

import SwiftUI
import SwiftData

/// Main container view for the food camera flow.
/// Manages transitions between camera → preview → processing → result states.
struct FoodCameraView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var onAddSuccess: (() -> Void)?
    
    @State private var viewModel = FoodCameraViewModel()
    @State private var showEditSheet = false
    @State private var showSuccess = false

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .camera, .capturing:
                cameraView
                    .transition(.opacity)

            case .preview:
                if let image = viewModel.capturedImage {
                    CapturePreviewView(
                        image: image,
                        cutoutImage: viewModel.cutoutImage,
                        outlineImage: viewModel.outlineImage,
                        isProcessing: viewModel.isExtractingCutout,
                        onConfirm: {
                            viewModel.confirmPreview()
                        },
                        onRetake: {
                            viewModel.retake()
                        },
                        onCrop: {
                            // Crop functionality placeholder
                        }
                    )
                    .transition(.opacity)
                }

            case .processing:
                if let image = viewModel.capturedImage {
                    ScanningOverlayView(image: image)
                        .transition(.opacity)
                }

            case .result, .editing:
                if let result = viewModel.recognitionResult {
                    resultView(result)
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                }
            }

            // Success overlay
            if showSuccess {
                successOverlay
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.state)
        .animation(.easeInOut(duration: 0.2), value: showSuccess)
        .sheet(isPresented: $showEditSheet) {
            FoodEditSheet(
                name: $viewModel.editedName,
                calories: $viewModel.editedCalories,
                carbs: $viewModel.editedCarbs,
                protein: $viewModel.editedProtein,
                fat: $viewModel.editedFat,
                onSave: {
                    viewModel.saveEdits()
                    showEditSheet = false
                },
                onCancel: {
                    viewModel.cancelEditing()
                    showEditSheet = false
                }
            )
        }
    }

    // MARK: - Camera View

    private var cameraView: some View {
        CustomCameraPreview(
            onCapture: { image in
                viewModel.capturePhoto(image)
            },
            onCancel: {
                dismiss()
            },
            onPickFromLibrary: { image in
                viewModel.capturePhoto(image)
            }
        )
    }

    // MARK: - Result View

    private func resultView(_ result: FoodRecognitionResult) -> some View {
        FoodStickerResultView(
            result: result,
            onRetake: {
                viewModel.retake()
            },
            onConfirm: {
                confirmAndSave()
            },
            onCancel: {
                dismissWithAnimation()
            },
            onEdit: {
                viewModel.startEditing()
                showEditSheet = true
            },
            onRetry: result.status.canRetry ? {
                viewModel.retryRecognition()
            } : nil
        )
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.paceRounded(size: 72))
                    .foregroundStyle(.green)

                Text(AppSettingsManager.shared.localized(.added))
                    .font(.paceRounded(.title2, weight: .black))
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Actions

    private func confirmAndSave() {
        guard let entry = viewModel.createFoodEntry() else { return }

        modelContext.insert(entry)
        showSuccess = true
        onAddSuccess?()

        // Dismiss after showing success, then parent will switch to Food Log
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            dismiss()
        }
    }

    private func dismissWithAnimation() {
        dismiss()
    }
}

// MARK: - Capture Preview View

struct CapturePreviewView: View {
    let image: UIImage
    let cutoutImage: UIImage?
    let outlineImage: UIImage?  // Pre-generated white silhouette for sticker border
    let isProcessing: Bool
    let onConfirm: () -> Void
    let onRetake: () -> Void
    let onCrop: () -> Void

    @State private var cutoutScale: CGFloat = 0.8
    @State private var cutoutOpacity: CGFloat = 0

    var body: some View {
        ZStack {
            // Blurred background from original image
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .blur(radius: 20)
                .ignoresSafeArea()

            // Semi-transparent overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack {
                Spacer()

                // Cutout preview with sticker style
                if let cutout = cutoutImage {
                    StickerImageView(
                        cutoutImage: cutout,
                        outlineImage: outlineImage,
                        maxWidth: 520,
                        maxHeight: 600
                    )
                    .scaleEffect(cutoutScale)
                    .opacity(cutoutOpacity)
                    .onAppear {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            cutoutScale = 1.0
                            cutoutOpacity = 1.0
                        }
                    }
                } else if isProcessing {
                    // Show spinner while extracting cutout
                    VStack(spacing: 16) {
                        SpinningRainbowRing()
                        Text(AppSettingsManager.shared.localized(.processing))
                            .font(.paceRounded(.subheadline))
                            .foregroundStyle(.white)
                    }
                } else {
                    // Fallback to original image
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 320, maxHeight: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Spacer()

                // Bottom controls
                bottomControls
                    .padding(.bottom, 50)
            }
        }
    }

    private var bottomControls: some View {
        HStack(spacing: 50) {
            // Retake button
            Button {
                onRetake()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.paceRounded(.title2))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.black.opacity(0.3), in: Circle())
            }

            // Confirm button (checkmark with orange color)
            Button {
                onConfirm()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 72, height: 72)

                    Image(systemName: "checkmark")
                        .font(.paceRounded(size: 28, weight: .bold))
                        .foregroundStyle(.orange)
                }
            }
            .disabled(isProcessing)
            .opacity(isProcessing ? 0.5 : 1.0)

            // Crop button
            Button {
                onCrop()
            } label: {
                Image(systemName: "crop")
                    .font(.paceRounded(.title2))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.black.opacity(0.3), in: Circle())
            }
        }
    }
}

// MARK: - Sticker Image View (Reusable)

/// Displays a cutout image with sticker-style white border.
/// Uses pre-generated outline for high-quality edge rendering.
struct StickerImageView: View {
    let cutoutImage: UIImage
    let outlineImage: UIImage?
    var maxWidth: CGFloat = 600
    var maxHeight: CGFloat = 700
    
    var body: some View {
        ZStack {
            // White outline (pre-generated or fallback)
            if let outline = outlineImage {
                // High-quality pre-rendered outline
                Image(uiImage: outline)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: maxWidth, maxHeight: maxHeight)
            } else {
                // Fallback: SwiftUI-based outline (lower quality)
                Image(uiImage: cutoutImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: maxWidth, maxHeight: maxHeight)
                    .colorMultiply(.white)
                    .blur(radius: 3)
                    .scaleEffect(1.04)
            }
            
            // Main cutout image on top
            Image(uiImage: cutoutImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: maxWidth, maxHeight: maxHeight)
        }
        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
    }
}

// MARK: - Preview

#Preview {
    FoodCameraView()
        .modelContainer(for: FoodEntry.self, inMemory: true)
}
