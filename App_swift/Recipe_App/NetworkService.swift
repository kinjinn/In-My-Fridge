// NetworkService.swift
import Foundation

class NetworkService {
    // A shared instance for easy access
    static let shared = NetworkService()
    private init() {}
    
    // Add this function inside the NetworkService class

    func addIngredient(name: String, quantity: String, accessToken: String, completion: @escaping (Ingredient?, Error?) -> Void) {
        guard let url = URL(string: "http://localhost:5001/api/ingredients") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Prepare the data to send in the request body
        let body = ["name": name, "quantity": quantity]
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    // The server responds with the newly created ingredient
                    let newIngredient = try JSONDecoder().decode(Ingredient.self, from: data)
                    DispatchQueue.main.async {
                        completion(newIngredient, nil)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            } else if let error = error {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }.resume()
    }
    
    func fetchIngredients(accessToken: String, completion: @escaping ([Ingredient]?, Error?) -> Void) {
        // 1. Set up the URL
        guard let url = URL(string: "http://localhost:5001/api/ingredients") else {
            completion(nil, NSError(domain: "NetworkService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }

        // 2. Create the URLRequest and add the Authorization header
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // --- ADD THIS DEBUG CODE ---
        print("--- Sending Token to Server ---")
        print("Value being sent: Bearer \(accessToken)")
        print("-----------------------------")
        // --- END DEBUG CODE ---
        
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        
        // 3. Create and run the data task
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle errors
            if let error = error {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }

            // Ensure we have data
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, NSError(domain: "NetworkService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                }
                return
            }
            
            // ... inside your dataTask completion handler, right after you check for data ...

            // This will print EXACTLY what the server sent to your app
            if let jsonString = String(data: data, encoding: .utf8) {
                print("--- ACTUAL SERVER RESPONSE ---")
                print(jsonString)
                print("----------------------------")
            }

            do {
                let ingredients = try JSONDecoder().decode([Ingredient].self, from: data)
                // ...
            } catch {
                // This will print the precise reason the decoding failed
                print("--- PRECISE DECODING ERROR ---")
                print(error)
                print("------------------------------")
                // ...
            }

            // 4. Decode the JSON data into our Ingredient structs
            do {
                let ingredients = try JSONDecoder().decode([Ingredient].self, from: data)
                DispatchQueue.main.async {
                    completion(ingredients, nil)
                }
            } catch let decodingError {
                DispatchQueue.main.async {
                    completion(nil, decodingError)
                }
            }
        }.resume() // Don't forget to start the task!
    }
}
