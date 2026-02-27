//
//  FoodRecognitionService.swift
//  Pace
//
//  Food recognition using Aliyun qwen-vl Vision API.
//  Images are processed in memory only, never persisted.
//

import UIKit
import Foundation

// MARK: - Recognition Result

struct FoodRecognitionResponse: Equatable {
    let name: String           // English name
    let nameCN: String         // Chinese name
    let calories: Int
    let carbs: Int      // grams
    let protein: Int    // grams
    let fat: Int        // grams
    
    /// Localized name based on current language setting
    var localizedName: String {
        let language = AppSettingsManager.shared.language
        switch language {
        case .chinese:
            return nameCN.isEmpty ? name : nameCN
        case .english:
            return name
        }
    }
    
    /// Fallback result when API fails
    static let unknown = FoodRecognitionResponse(
        name: "Unknown Food",
        nameCN: "未知食物",
        calories: 0,
        carbs: 0,
        protein: 0,
        fat: 0
    )
}

// MARK: - Service Errors

enum FoodRecognitionError: Error, LocalizedError {
    case invalidImage
    case networkError(Error)
    case apiError(String)
    case parseError(String)
    case rateLimited
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Failed to process image"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message):
            return "API error: \(message)"
        case .parseError(let message):
            return "Failed to parse response: \(message)"
        case .rateLimited:
            return "Too many requests, please try again later"
        }
    }
}

// MARK: - Service

/// Service for recognizing food items from images using Aliyun qwen-vl Vision API.
/// Privacy: Images are sent directly to API, processed in memory, never stored.
final class FoodRecognitionService {
    
    // MARK: - Configuration
    
    // ⚠️ TODO: [MUST FIX BEFORE RELEASE] Replace with proxy server
    // Current: hardcoded for development only. Before release:
    // 1. Deploy Cloudflare Workers / Vercel Edge Function proxy
    // 2. Store API Key in proxy server environment variables
    // 3. iOS client calls proxy endpoint only, never exposes API Key
    // See readme.md "Security Checklist" section for details
    private static let apiKey = "sk-88c8f9a1a75a48289e22798b573c697f"
    private static let baseURL = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
    private static let model = "qwen3-vl-plus"
    
    // MARK: - Public API
    
    /// Recognize food from image and return nutritional information.
    /// Image is processed in memory only, never persisted.
    ///
    /// - Parameter image: The food image (typically a cutout from VisionKit)
    /// - Returns: Recognition result with food name and nutrition data
    /// - Throws: FoodRecognitionError if recognition fails
    func recognizeFood(from image: UIImage) async throws -> FoodRecognitionResponse {
        // Convert image to base64 (in memory only)
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw FoodRecognitionError.invalidImage
        }
        let base64Image = imageData.base64EncodedString()
        
        // Build request
        let request = try buildRequest(base64Image: base64Image)
        
        // Execute request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check HTTP status
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 429 {
                throw FoodRecognitionError.rateLimited
            }
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw FoodRecognitionError.apiError("HTTP \(httpResponse.statusCode): \(errorMessage)")
            }
        }
        
        // Parse response
        return try parseResponse(data: data)
    }
    
    // MARK: - Private Methods
    
    private func buildRequest(base64Image: String) throws -> URLRequest {
        guard let url = URL(string: Self.baseURL) else {
            throw FoodRecognitionError.apiError("Invalid API URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Self.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        // Build prompt for food recognition with bilingual support
        let prompt = """
        请识别这张图片中的食物，并以 JSON 格式返回以下信息：
        - name: 食物名称（英文）
        - nameCN: 食物名称（中文）
        - calories: 估算热量（kcal，整数）
        - carbs: 碳水化合物（克，整数）
        - protein: 蛋白质（克，整数）
        - fat: 脂肪（克，整数）
        
        只返回 JSON，不要其他文字。示例格式：
        {"name": "Coffee", "nameCN": "咖啡", "calories": 5, "carbs": 1, "protein": 0, "fat": 0}
        
        如果无法识别或图片中没有食物，返回：
        {"name": "Unknown", "nameCN": "未知", "calories": 0, "carbs": 0, "protein": 0, "fat": 0}
        """
        
        let body: [String: Any] = [
            "model": Self.model,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ],
                        [
                            "type": "text",
                            "text": prompt
                        ]
                    ]
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
    
    private func parseResponse(data: Data) throws -> FoodRecognitionResponse {
        // Parse API response structure
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw FoodRecognitionError.parseError("Invalid response structure")
        }
        
        // Extract JSON from content (may contain markdown code blocks)
        let jsonString = extractJSON(from: content)
        
        guard let jsonData = jsonString.data(using: .utf8),
              let foodInfo = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw FoodRecognitionError.parseError("Failed to parse food info JSON")
        }
        
        // Extract values with defaults
        let name = foodInfo["name"] as? String ?? "Unknown"
        let nameCN = foodInfo["nameCN"] as? String ?? ""
        let calories = (foodInfo["calories"] as? Int) ?? Int(foodInfo["calories"] as? Double ?? 0)
        let carbs = (foodInfo["carbs"] as? Int) ?? Int(foodInfo["carbs"] as? Double ?? 0)
        let protein = (foodInfo["protein"] as? Int) ?? Int(foodInfo["protein"] as? Double ?? 0)
        let fat = (foodInfo["fat"] as? Int) ?? Int(foodInfo["fat"] as? Double ?? 0)
        
        return FoodRecognitionResponse(
            name: name,
            nameCN: nameCN,
            calories: calories,
            carbs: carbs,
            protein: protein,
            fat: fat
        )
    }
    
    /// Extract JSON from content that may contain markdown code blocks
    private func extractJSON(from content: String) -> String {
        var result = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code blocks if present
        if result.hasPrefix("```json") {
            result = String(result.dropFirst(7))
        } else if result.hasPrefix("```") {
            result = String(result.dropFirst(3))
        }
        
        if result.hasSuffix("```") {
            result = String(result.dropLast(3))
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
