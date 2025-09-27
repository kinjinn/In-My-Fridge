// NetworkService.swift
import Foundation

// This is the helper struct for decoding the AI's response in the preview function.
fileprivate struct IngredientPreview: Decodable {
    let name: String
    let quantity: String
}

class NetworkService {
    // A shared instance for easy access
    static let shared = NetworkService()
    private init() {}

    // MARK: - Fetch All Ingredients
    func fetchIngredients(accessToken: String, completion: @escaping ([Ingredient]?, Error?) -> Void) {
        guard let url = URL(string: "http://localhost:5001/api/ingredients") else {
            completion(nil, NSError(domain: "NetworkService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let data = data else {
                    completion(nil, NSError(domain: "NetworkService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                    return
                }

                do {
                    // The server sends back an array of ingredients for this endpoint
                    let ingredients = try JSONDecoder().decode([Ingredient].self, from: data)
                    completion(ingredients, nil)
                } catch {
                    // If decoding fails, print the error and the raw server response for debugging
                    print("❗️DECODING ERROR (fetchIngredients): \(error)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("--- RAW SERVER RESPONSE ---\n\(jsonString)\n-------------------------")
                    }
                    completion(nil, error)
                }
            }
        }.resume()
    }

    // MARK: - Add a Single Ingredient
    func addIngredient(name: String, quantity: String, accessToken: String, completion: @escaping (Ingredient?, Error?) -> Void) {
        guard let url = URL(string: "http://localhost:5001/api/ingredients") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["name": name, "quantity": quantity]
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let data = data else {
                    completion(nil, NSError(domain: "NetworkService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                    return
                }

                do {
                    // *** FIX: The server sends back a SINGLE new ingredient object, NOT an array. ***
                    let newIngredient = try JSONDecoder().decode(Ingredient.self, from: data)
                    completion(newIngredient, nil)
                } catch {
                    print("❗️DECODING ERROR (addIngredient): \(error)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("--- RAW SERVER RESPONSE ---\n\(jsonString)\n-------------------------")
                    }
                    completion(nil, error)
                }
            }
        }.resume()
    }
    
    // MARK: - Parse Voice to Preview
    func parseTextForPreview(text: String, accessToken: String, completion: @escaping ([Ingredient]?, Error?) -> Void) {
        guard let url = URL(string: "http://localhost:5001/api/ingredients/parse-preview") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["text": text]
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let data = data else {
                    completion(nil, NSError(domain: "NetworkService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                    return
                }

                do {
                    // 1. Decode the AI's response using the helper struct
                    let previewItems = try JSONDecoder().decode([IngredientPreview].self, from: data)
                    // 2. Convert the preview items into our standard Ingredient model for the UI
                    let ingredients = previewItems.map { Ingredient(id: UUID().uuidString, name: $0.name, quantity: $0.quantity) }
                    completion(ingredients, nil)
                } catch {
                    print("❗️DECODING ERROR (parseTextForPreview): \(error)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("--- RAW SERVER RESPONSE ---\n\(jsonString)\n-------------------------")
                    }
                    completion(nil, error)
                }
            }
        }.resume()
    }
}
