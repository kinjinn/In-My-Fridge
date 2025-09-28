import Foundation

struct Recipe: Codable, Identifiable {
    let id = UUID()
    let title: String
    let description: String?
    let ingredients_used: [String]
    let instructions: [String]
    private enum CodingKeys: String, CodingKey {
        case title, description, ingredients_used, instructions
    }
}
