// Ingredient.swift
import Foundation

// Conforms to Codable to be decoded from JSON and Identifiable for SwiftUI Lists
struct Ingredient: Codable, Identifiable {
    let id: String
    let name: String
    let quantity: String
    
    var isSelected: Bool = false;

    // This maps the "_id" from MongoDB to "id" in our struct
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case quantity
    }
}
