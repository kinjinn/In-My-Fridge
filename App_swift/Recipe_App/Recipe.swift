// Recipe.swift
import Foundation

struct Recipe: Codable, Identifiable {
    let id = UUID() // Add a unique ID for SwiftUI
    let title: String
    let description: String?
    let ingredients_used: [String]
    let instructions: [String]

    // We need this because 'id' is not in the JSON from the API
    private enum CodingKeys: String, CodingKey {
        case title, description, ingredients_used, instructions
    }
}
