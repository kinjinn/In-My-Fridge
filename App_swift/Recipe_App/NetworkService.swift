// NetworkService.swift
import Foundation
import UIKit

// This struct is used only for the AI's response from voice parsing
fileprivate struct IngredientPreview: Decodable, Sendable {
    let name: String
    let quantity: String
}

class NetworkService {
    static let shared = NetworkService()
    
    // ✅ IMPORTANT: Using the IP address from your working branch
    private let baseURL = "http://192.168.1.214:5001/api"
    
    private init() {}

    // MARK: - Ingredient Management
    
    func fetchIngredients(accessToken: String, completion: @escaping ([Ingredient]?, Error?) -> Void) {
        performRequest(endpoint: "/ingredients", method: "GET", accessToken: accessToken, completion: completion)
    }

    func addIngredient(name: String, quantity: String, accessToken: String, completion: @escaping (Ingredient?, Error?) -> Void) {
        let body = ["name": name, "quantity": quantity]
        performRequest(endpoint: "/ingredients", method: "POST", body: body, accessToken: accessToken, completion: completion)
    }
    
    func deleteIngredient(id: String, accessToken: String, completion: @escaping (Bool, Error?) -> Void) {
        guard let url = URL(string: "\(baseURL)/ingredients/\(id)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    completion(true, nil)
                } else {
                    completion(false, error)
                }
            }
        }.resume()
    }

    func updateIngredientQuantity(id: String, newQuantity: String, accessToken: String, completion: @escaping (Ingredient?, Error?) -> Void) {
        let body = ["quantity": newQuantity]
        performRequest(endpoint: "/ingredients/\(id)", method: "PATCH", body: body, accessToken: accessToken, completion: completion)
    }
    
    // MARK: - AI & Scanning Functions

    func parseTextForPreview(text: String, accessToken: String, completion: @escaping ([Ingredient]?, Error?) -> Void) {
        let body = ["text": text]
        performRequest(endpoint: "/ingredients/parse-preview", method: "POST", body: body, accessToken: accessToken) { (previewItems: [IngredientPreview]?, error: Error?) in
            if let items = previewItems {
                // Convert simple preview items into full Ingredient models for the UI
                let ingredients = items.map { Ingredient(id: UUID().uuidString, name: $0.name, quantity: $0.quantity, isSelected: true) }
                completion(ingredients, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func generateRecipes(ingredients: [String], accessToken: String, completion: @escaping ([Recipe]?, Error?) -> Void) {
        let body = ["ingredients": ingredients]
        performRequest(endpoint: "/recipes/generate", method: "POST", body: body, accessToken: accessToken, completion: completion)
    }
    
    func scanIngredients(from image: UIImage, accessToken: String, completion: @escaping ([ScannedIngredient]?, Error?) -> Void) {
        guard let url = URL(string: "\(baseURL)/ingredients/scan") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        var data = Data()
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"image\"; filename=\"fridge.jpg\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        data.append(image.jpegData(compressionQuality: 0.8)!)
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        URLSession.shared.uploadTask(with: request, from: data) { responseData, _, error in
            DispatchQueue.main.async {
                guard let responseData = responseData, error == nil else { completion(nil, error); return }
                do {
                    completion(try JSONDecoder().decode([ScannedIngredient].self, from: responseData), nil)
                } catch { completion(nil, error) }
            }
        }.resume()
    }
    
    func batchAddIngredients(ingredients: [ScannedIngredient], accessToken: String, completion: @escaping ([Ingredient]?, Error?) -> Void) {
        let body = ["ingredients": ingredients]
        performRequest(endpoint: "/ingredients/batch-add", method: "POST", body: body, accessToken: accessToken, completion: completion)
    }

    // MARK: - Private Generic Request Helper
    
    private func performRequest<T: Decodable, B: Encodable>(endpoint: String, method: String, body: B? = nil, accessToken: String, completion: @escaping (T?, Error?) -> Void) {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONEncoder().encode(body)
        }
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else { completion(nil, error); return }
                do {
                    completion(try JSONDecoder().decode(T.self, from: data), nil)
                } catch {
                    print("❗️DECODING ERROR for \(T.self): \(error)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("--- RAW FAILED RESPONSE --- \n\(responseString)\n---------------------------")
                    }
                    completion(nil, error)
                }
            }
        }.resume()
    }
    
    // Overload for requests without a body
    private func performRequest<T: Decodable>(endpoint: String, method: String, accessToken: String, completion: @escaping (T?, Error?) -> Void) {
        performRequest(endpoint: endpoint, method: method, body: Optional<String>.none, accessToken: accessToken, completion: completion)
    }
}
