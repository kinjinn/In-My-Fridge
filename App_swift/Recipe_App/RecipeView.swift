import SwiftUI

struct RecipesView: View {
    @Binding var recipes: [Recipe]
    @State private var expandedRecipeID: UUID?

    var body: some View {
        VStack(alignment: .leading) {
            Text("Generated Recipes").font(.largeTitle).padding()
            if recipes.isEmpty {
                Spacer()
                Text("No recipes yet. Select some ingredients and tap 'Generate'!")
                    .foregroundColor(.secondary).padding().frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(recipes) { recipe in
                            recipeCard(for: recipe)
                        }
                    }.padding(.horizontal)
                }
            }
        }
    }

    @ViewBuilder
    private func recipeCard(for recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(recipe.title).font(.headline)
                Spacer()
                Image(systemName: "chevron.down")
                    .rotationEffect(.degrees(expandedRecipeID == recipe.id ? 180 : 0))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut) {
                    expandedRecipeID = (expandedRecipeID == recipe.id) ? nil : recipe.id
                }
            }
            
            if expandedRecipeID == recipe.id {
                VStack(alignment: .leading, spacing: 8) {
                    if let desc = recipe.description, !desc.isEmpty {
                        Text(desc).font(.caption).foregroundColor(.secondary)
                    }
                    Divider()
                    Text("Instructions").fontWeight(.bold)
                    ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top) { Text("\(index + 1)."); Text(step) }
                    }
                }.transition(.opacity)
            }
        }
        .padding().background(Color(.systemGray5)).cornerRadius(10)
    }
}
