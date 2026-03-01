//
//  FoodCameraView.swift
//  Pace
//

import SwiftUI
import SwiftData
import ActivityKit

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
        print("[FoodCameraView] Rendering with state: \(viewModel.state)")
        return ZStack {
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
        print("[FoodCameraView] Creating camera view")
        return CustomCameraPreview(
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
        
        // Update Live Activity after adding food
        updateLiveActivity()

        // Dismiss after showing success, then parent will switch to Food Log
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            dismiss()
        }
    }
    
    private func updateLiveActivity() {
        // Fetch all entries from model context to calculate remaining values
        let descriptor = FetchDescriptor<FoodEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        guard let allEntries = try? modelContext.fetch(descriptor) else { return }
        
        // Get user profile for daily targets
        let userProfile = UserProfile.load()
        let dailyCalories = userProfile.dailyCalories
        
        // Calculate consumed values
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todaysEntries = allEntries.filter { 
            calendar.startOfDay(for: $0.timestamp) == today 
        }
        
        let consumedCalories = todaysEntries.reduce(0) { $0 + $1.calories }
        let consumedCarbs = todaysEntries.reduce(0) { $0 + $1.carbs }
        let consumedProtein = todaysEntries.reduce(0) { $0 + $1.protein }
        let consumedFat = todaysEntries.reduce(0) { $0 + $1.fat }
        
        // Calculate daily macros
        let dailyCarbs = Int(Double(dailyCalories) * 0.45 / 4.0)
        let dailyProtein = Int(Double(dailyCalories) * 0.25 / 4.0)
        let dailyFat = Int(Double(dailyCalories) * 0.30 / 9.0)
        
        // Update Live Activity
        LiveActivityService.shared.update(
            remainingCalories: dailyCalories - consumedCalories,
            remainingCarbs: max(0, dailyCarbs - consumedCarbs),
            remainingProtein: max(0, dailyProtein - consumedProtein),
            remainingFat: max(0, dailyFat - consumedFat)
        )
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

// MARK: - Preview

#Preview {
    FoodCameraView()
        .modelContainer(for: FoodEntry.self, inMemory: true)
}
