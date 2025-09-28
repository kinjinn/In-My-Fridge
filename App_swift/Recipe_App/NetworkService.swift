import Foundation

fileprivate struct IngredientPreview: Decodable { let name: String, quantity: String }

class NetworkService {
    static let shared = NetworkService()
    private let baseURL = "http://localhost:5001/api"
    private init() {}

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
                } else { completion(false, error) }
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
        guard let url = URL(string: "\(baseURL)/ingredients/parse-preview") else { return }
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
        let body = ["ingredients": ingredients]
        performRequest(endpoint: "/recipes/generate", method: "POST", body: body, accessToken: accessToken, completion: completion)
    }

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
