//
//  FoodCameraViewModel.swift
//  Pace
//

import Foundation
import UIKit
import SwiftUI

// MARK: - Flow State

enum FoodCameraState: Equatable {
    case camera
    case capturing      // Shutter pressed
    case preview        // Shows preview and cutout result
    case processing     // AI processing
    case result         // Shows result
    case editing        // Edit mode
}

// MARK: - Recognition Status

/// Status of food recognition with humorous fallback messages
enum RecognitionStatus: Equatable {
    case success
    case notFood            // Detected but not a food item
    case mystery            // Could not identify
    case networkError       // Connection issue (retryable)
    case timeout            // Request took too long (retryable)
    case serviceError       // API/server issue (retryable)
    
    /// Whether the user can retry the recognition
    var canRetry: Bool {
        switch self {
        case .networkError, .timeout, .serviceError:
            return true
        default:
            return false
        }
    }
    
    /// Emoji badge for the sticker
    var badge: String {
        switch self {
        case .success: return ""
        case .notFood: return "🤔"
        case .mystery: return "🔮"
        case .networkError: return "📡"
        case .timeout: return "💤"
        case .serviceError: return "🔧"
        }
    }
    
    /// Humorous headline for the result card
    var headline: String {
        switch self {
        case .success: return ""
        case .notFood: return "Interesting Find!"
        case .mystery: return "Mystery Item"
        case .networkError: return "Lost Connection"
        case .timeout: return "AI Took a Nap"
        case .serviceError: return "Oops!"
        }
    }
    
    /// Witty subtitle for the result card
    var subtitle: String {
        switch self {
        case .success: 
            return ""
        case .notFood: 
            return "Looks cool, but is it edible? You tell us."
        case .mystery: 
            return "The AI is confused. Help it out?"
        case .networkError: 
            return "The AI went offline for a snack. Retry?"
        case .timeout: 
            return "Still thinking... or maybe dreaming of food."
        case .serviceError: 
            return "Something went wrong on our end. Give it another shot?"
        }
    }
    
    /// Color theme for the status
    var accentColor: Color {
        switch self {
        case .success: return .orange
        case .notFood: return .purple
        case .mystery: return .indigo
        case .networkError, .timeout, .serviceError: return .gray
        }
    }
}

// MARK: - Food Recognition Result

struct FoodRecognitionResult: Equatable {
    let name: String
    let calories: Int
    let carbs: Int      // grams
    let protein: Int    // grams
    let fat: Int        // grams
    let originalImage: UIImage
    let cutoutImage: UIImage?
    let outlineImage: UIImage?  // White silhouette for sticker border
    let status: RecognitionStatus
    
    /// Create result from API response
    static func from(
        response: FoodRecognitionResponse,
        originalImage: UIImage,
        cutoutImage: UIImage?,
        outlineImage: UIImage?,
        status: RecognitionStatus = .success
    ) -> FoodRecognitionResult {
        FoodRecognitionResult(
            name: response.localizedName,  // Use localized name
            calories: response.calories,
            carbs: response.carbs,
            protein: response.protein,
            fat: response.fat,
            originalImage: originalImage,
            cutoutImage: cutoutImage,
            outlineImage: outlineImage,
            status: status
        )
    }
}

// MARK: - ViewModel

@Observable
final class FoodCameraViewModel {
    
    // MARK: - State

    private(set) var state: FoodCameraState = .camera
    private(set) var capturedImage: UIImage?
    private(set) var cutoutImage: UIImage?
    private(set) var outlineImage: UIImage?  // White silhouette for sticker border
    private(set) var recognitionResult: FoodRecognitionResult?
    private(set) var isExtractingCutout: Bool = false
    private(set) var isRetrying: Bool = false
    
    // Editable fields for correction mode
    var editedName: String = ""
    var editedCalories: String = ""
    var editedCarbs: String = ""
    var editedProtein: String = ""
    var editedFat: String = ""
    
    // MARK: - Dependencies
    
    private let cutoutService: ImageCutoutService = {
        let service = ImageCutoutService()
        // Optimized settings for food sticker effect
        service.featherRadius = 1.5      // Soft edges
        service.edgeErosionRadius = 1.0  // Remove background artifacts
        return service
    }()
    
    private let recognitionService = FoodRecognitionService()
    
    // MARK: - Actions
    
    /// Called when shutter button is pressed
    func capturePhoto(_ image: UIImage) {
        print("[FoodCameraViewModel] 📸 capturePhoto called, image size: \(image.size)")
        capturedImage = image
        state = .capturing
        isExtractingCutout = true
        print("[FoodCameraViewModel] State changed to: \(state)")

        // Brief delay for capture animation, then show preview
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.state = .preview
            print("[FoodCameraViewModel] State changed to: \(self?.state ?? .camera)")
            self?.startCutoutExtraction()
        }
    }

    /// Extract cutout and outline in preview state
    private func startCutoutExtraction() {
        guard let image = capturedImage else {
            print("[FoodCameraViewModel] ❌ Cannot extract cutout - capturedImage is nil")
            return
        }
        print("[FoodCameraViewModel] 🔍 Starting cutout extraction for image: \(image.size)")

        Task {
            // Extract cutout and outline in parallel
            async let cutoutTask = cutoutService.extractForeground(from: image)
            async let outlineTask = cutoutService.generateStickerOutline(from: image, outlineWidth: 28)
            
            let (cutout, outline) = await (cutoutTask, outlineTask)
            print("[FoodCameraViewModel] ✅ Cutout extraction complete - cutout: \(cutout != nil ? "success" : "nil"), outline: \(outline != nil ? "success" : "nil")")

            await MainActor.run {
                self.cutoutImage = cutout
                self.outlineImage = outline
                self.isExtractingCutout = false
            }
        }
    }

    /// User confirms the preview and proceeds to AI recognition
    func confirmPreview() {
        print("[FoodCameraViewModel] 👆 confirmPreview called")
        state = .processing
        print("[FoodCameraViewModel] State changed to: \(state)")
        startProcessing()
    }

    /// Start AI processing with real API call
    private func startProcessing() {
        // Use cutout image for recognition if available, otherwise original
        guard let imageToRecognize = cutoutImage ?? capturedImage else {
            print("[FoodCameraViewModel] ❌ Cannot start processing - no image available")
            return
        }
        print("[FoodCameraViewModel] 🤖 Starting AI recognition...")
        
        Task {
            do {
                let response = try await recognitionService.recognizeFood(from: imageToRecognize)
                print("[FoodCameraViewModel] ✅ Recognition success: \(response.localizedName)")
                await MainActor.run {
                    completeProcessing(with: response)
                }
            } catch {
                print("[FoodCameraViewModel] ❌ Recognition failed: \(error)")
                await MainActor.run {
                    handleRecognitionError(error)
                }
            }
        }
    }
    
    /// Complete processing with API response
    private func completeProcessing(with response: FoodRecognitionResponse, status: RecognitionStatus = .success) {
        guard let image = capturedImage else { return }
        
        // Detect "not food" from API response
        let finalStatus: RecognitionStatus
        if status == .success {
            // Check if API returned "Unknown" or generic responses
            let lowercaseName = response.name.lowercased()
            let lowercaseNameCN = response.nameCN.lowercased()
            if lowercaseName == "unknown" || lowercaseName == "unknown food" || lowercaseNameCN == "未知" || lowercaseNameCN == "未知食物" {
                finalStatus = .mystery
            } else if response.calories == 0 && (lowercaseName.contains("object") || lowercaseName.contains("item")) {
                finalStatus = .notFood
            } else {
                finalStatus = .success
            }
        } else {
            finalStatus = status
        }
        
        recognitionResult = FoodRecognitionResult.from(
            response: response,
            originalImage: image,
            cutoutImage: cutoutImage,
            outlineImage: outlineImage,
            status: finalStatus
        )
        
        // Populate editable fields
        if let result = recognitionResult {
            editedName = result.name
            editedCalories = "\(result.calories)"
            editedCarbs = "\(result.carbs)"
            editedProtein = "\(result.protein)"
            editedFat = "\(result.fat)"
        }
        
        isRetrying = false
        state = .result
    }
    
    /// Handle recognition errors - map to status and show sticker with humor
    private func handleRecognitionError(_ error: Error) {
        print("[FoodCameraViewModel] ⚠️ Recognition error: \(error.localizedDescription)")
        print("[FoodCameraViewModel] Error type: \(type(of: error))")
        
        // Map error to recognition status
        let status: RecognitionStatus
        if let recognitionError = error as? FoodRecognitionError {
            switch recognitionError {
            case .networkError:
                status = .networkError
            case .rateLimited, .apiError:
                status = .serviceError
            case .parseError:
                status = .mystery
            case .invalidImage:
                status = .notFood
            }
        } else if (error as NSError).code == NSURLErrorTimedOut {
            status = .timeout
        } else {
            status = .networkError
        }
        
        // Still show a sticker! Just with a different vibe
        completeProcessing(with: .unknown, status: status)
    }
    
    /// Retry recognition (for network/timeout errors)
    func retryRecognition() {
        guard let result = recognitionResult, result.status.canRetry else { return }
        
        isRetrying = true
        state = .processing
        startProcessing()
    }
    
    /// Retake photo
    func retake() {
        print("[FoodCameraViewModel] 🔄 Retake called")
        capturedImage = nil
        cutoutImage = nil
        outlineImage = nil
        recognitionResult = nil
        isExtractingCutout = false
        isRetrying = false
        state = .camera
        print("[FoodCameraViewModel] State reset to: \(state)")
    }
    
    /// Enter editing mode
    func startEditing() {
        state = .editing
    }
    
    /// Save edits and return to result
    func saveEdits() {
        // Update result with edited values
        guard let original = recognitionResult else { return }
        
        recognitionResult = FoodRecognitionResult(
            name: editedName,
            calories: Int(editedCalories) ?? original.calories,
            carbs: Int(editedCarbs) ?? original.carbs,
            protein: Int(editedProtein) ?? original.protein,
            fat: Int(editedFat) ?? original.fat,
            originalImage: original.originalImage,
            cutoutImage: original.cutoutImage,
            outlineImage: original.outlineImage,
            status: .success  // User edited = success
        )
        
        state = .result
    }
    
    /// Cancel editing
    func cancelEditing() {
        // Restore original values
        if let result = recognitionResult {
            editedName = result.name
            editedCalories = "\(result.calories)"
            editedCarbs = "\(result.carbs)"
            editedProtein = "\(result.protein)"
            editedFat = "\(result.fat)"
        }
        state = .result
    }
    
    /// Create food entry from current result
    func createFoodEntry() -> FoodEntry? {
        print("[FoodCameraViewModel] 📝 createFoodEntry called")
        guard let result = recognitionResult else {
            print("[FoodCameraViewModel] ❌ Cannot create entry - recognitionResult is nil")
            return nil
        }
        print("[FoodCameraViewModel] Creating entry for: \(result.name)")
        
        // Save cutout image as PNG data (preserves transparency)
        var imageData: Data? = nil
        if let cutout = result.cutoutImage {
            imageData = cutout.pngData()
        }
        
        return FoodEntry(
            name: result.name,
            calories: result.calories,
            carbs: result.carbs,
            protein: result.protein,
            fat: result.fat,
            portion: "1 serving",
            cutoutImageData: imageData
        )
    }
}
