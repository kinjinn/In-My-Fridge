// NetworkService.swift
import Foundation
import UIKit // 1. Import UIKit to handle UIImage

class NetworkService {
    // A shared instance for easy access
    static let shared = NetworkService()
    private init() {}
    
    // MARK: - Standard Ingredient and Recipe Functions
    
    func addIngredient(name: String, quantity: String, accessToken: String, completion: @escaping (Ingredient?, Error?) -> Void) {
        guard let url = URL(string: "http://192.168.1.214:5001/api/ingredients") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["name": name, "quantity": quantity]
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let newIngredient = try JSONDecoder().decode(Ingredient.self, from: data)
                    DispatchQueue.main.async { completion(newIngredient, nil) }
                } catch {
                    DispatchQueue.main.async { completion(nil, error) }
                }
            } else if let error = error {
                DispatchQueue.main.async { completion(nil, error) }
            }
        }.resume()
    }
    
    func fetchIngredients(accessToken: String, completion: @escaping ([Ingredient]?, Error?) -> Void) {
        guard let url = URL(string: "http://192.168.1.214:5001/api/ingredients") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let ingredients = try JSONDecoder().decode([Ingredient].self, from: data)
                    DispatchQueue.main.async { completion(ingredients, nil) }
                } catch {
                    DispatchQueue.main.async { completion(nil, error) }
                }
            } else if let error = error {
                DispatchQueue.main.async { completion(nil, error) }
            }
        }.resume()
    }
    
    func generateRecipes(ingredients: [String], accessToken: String, completion: @escaping ([Recipe]?, Error?) -> Void) {
        guard let url = URL(string: "http://192.168.1.214:5001/api/recipes/generate") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["ingredients": ingredients]
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let recipes = try JSONDecoder().decode([Recipe].self, from: data)
                    DispatchQueue.main.async { completion(recipes, nil) }
                } catch {
                    DispatchQueue.main.async { completion(nil, error) }
                }
            } else if let error = error {
                DispatchQueue.main.async { completion(nil, error) }
            }
        }.resume()
    }
    
    // MARK: - NEW Image Scanning Functions
    
    // 2. This function uploads the image and decodes the AI's response
    func scanIngredients(from image: UIImage, accessToken: String, completion: @escaping ([ScannedIngredient]?, Error?) -> Void) {
        guard let url = URL(string: "http://192.168.1.214:5001/api/ingredients/scan") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        var data = Data()
        
        // Add the image data to the request body
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"image\"; filename=\"fridge.jpg\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        data.append(image.jpegData(compressionQuality: 0.8)!)
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        URLSession.shared.uploadTask(with: request, from: data) { responseData, response, error in
            if let responseData = responseData {
                do {
                    let ingredients = try JSONDecoder().decode([ScannedIngredient].self, from: responseData)
                    DispatchQueue.main.async { completion(ingredients, nil) }
                } catch {
                    DispatchQueue.main.async { completion(nil, error) }
                }
            } else if let error = error {
                DispatchQueue.main.async { completion(nil, error) }
            }
        }.resume()
    }
    
    // 3. This function sends the scanned ingredients to be saved in the database
    func batchAddIngredients(ingredients: [ScannedIngredient], accessToken: String, completion: @escaping ([Ingredient]?, Error?) -> Void) {
        guard let url = URL(string: "http://192.168.1.214:5001/api/ingredients/batch-add") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["ingredients": ingredients]
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let newIngredients = try JSONDecoder().decode([Ingredient].self, from: data)
                    DispatchQueue.main.async { completion(newIngredients, nil) }
                } catch {
                    DispatchQueue.main.async { completion(nil, error) }
                }
            } else if let error = error {
                DispatchQueue.main.async { completion(nil, error) }
            }
        }.resume()
    }
}
