import Foundation
import UIKit

fileprivate struct IngredientPreview: Decodable { let name: String, quantity: String }

class NetworkService {
    static let shared = NetworkService()
    private let baseApiUrl = "http://192.168.1.214:5001/api"
    private init() {}

    func fetchIngredients(accessToken: String, completion: @escaping ([Ingredient]?, Error?) -> Void) {
        guard let url = URL(string: "\(baseApiUrl)/ingredients") else { return }
        performRequest(endpoint: "/ingredients", method: "GET", accessToken: accessToken, completion: completion)
    }

    func addIngredient(name: String, quantity: String, accessToken: String, completion: @escaping (Ingredient?, Error?) -> Void) {
        guard let url = URL(string: "\(baseApiUrl)/ingredients") else { return }
        let body = ["name": name, "quantity": quantity]
        performRequest(endpoint: "/ingredients", method: "POST", body: body, accessToken: accessToken, completion: completion)
    }
    
    func deleteIngredient(id: String, accessToken: String, completion: @escaping (Bool, Error?) -> Void) {
        guard let url = URL(string: "\(baseApiUrl)/ingredients/\(id)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    completion(true, nil)
                } else { completion(false, error) }
            }
        }.resume()
    }
    
    // 2. This function uploads the image and decodes the AI's response
    func scanIngredients(from image: UIImage, accessToken: String, completion: @escaping ([ScannedIngredient]?, Error?) -> Void) {
        guard let url = URL(string: "\(baseApiUrl)/ingredients/scan") else { return }
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
        guard let url = URL(string: "\(baseApiUrl)/ingredients/batch-add") else { return }
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

    func updateIngredientQuantity(id: String, newQuantity: String, accessToken: String, completion: @escaping (Ingredient?, Error?) -> Void) {
        guard let url = URL(string: "http://localhost:5001/api/ingredients/\(id)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Encode the new quantity in the request body
        let body = ["quantity": newQuantity]
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    completion(nil, error)
                    return
                }
                do {
                    let updatedIngredient = try JSONDecoder().decode(Ingredient.self, from: data)
                    completion(updatedIngredient, nil)
                } catch {
                    completion(nil, error)
                }
            }
        }.resume()
    }

    func parseTextForPreview(text: String, accessToken: String, completion: @escaping ([Ingredient]?, Error?) -> Void) {
        guard let url = URL(string: "\(baseApiUrl)/ingredients/parse-preview") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["text": text])
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else { completion(nil, error); return }
                do {
                    let previewItems = try JSONDecoder().decode([IngredientPreview].self, from: data)
                    let ingredients = previewItems.map { Ingredient(id: UUID().uuidString, name: $0.name, quantity: $0.quantity) }
                    completion(ingredients, nil)
                } catch { completion(nil, error) }
            }
        }.resume()
    }
    
    func generateRecipes(ingredients: [String], accessToken: String, completion: @escaping ([Recipe]?, Error?) -> Void) {
        guard let url = URL(string: "\(baseApiUrl)/recipes/generate") else { return }
        let body = ["ingredients": ingredients]
        performRequest(endpoint: "/recipes/generate", method: "POST", body: body, accessToken: accessToken, completion: completion)
    }

    private func performRequest<T: Decodable, B: Encodable>(endpoint: String, method: String, body: B? = nil, accessToken: String, completion: @escaping (T?, Error?) -> Void) {
        guard let url = URL(string: "\(baseApiUrl)\(endpoint)") else { return }
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
                    completion(nil, error)
                }
            }
        }.resume()
    }
}

extension NetworkService {
    private func performRequest<T: Decodable>(endpoint: String, method: String, accessToken: String, completion: @escaping (T?, Error?) -> Void) {
        performRequest(endpoint: endpoint, method: method, body: Optional<String>.none, accessToken: accessToken, completion: completion)
    }
}
