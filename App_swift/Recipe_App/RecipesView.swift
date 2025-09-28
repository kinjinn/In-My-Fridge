import SwiftUI

struct RecipesView: View {
    var recipes: [Recipe]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Recipes")
                .font(.title)
                .padding(.bottom)
            
            if recipes.isEmpty {
                Text("No recipes yet. Generate some from your ingredients!")
                    .foregroundColor(.secondary)
                    .padding()
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(recipes) { recipe in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(recipe.title)
                                    .font(.headline)
                                if let description = recipe.description {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Divider()
                                Text("Instructions")
                                    .fontWeight(.bold)
                                ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, step in
                                    Text("\(index + 1). \(step)")
                                }
                            }
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
    }
}
