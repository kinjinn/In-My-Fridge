import SwiftUI

struct RecipesView: View {
    @Binding var recipes: [Recipe]

    @State private var expandedRecipeID: UUID?

    var body: some View {
        VStack(alignment: .leading) {
            Text("Recipes")
                .font(.title)
                .padding([.top, .horizontal])
                .padding(.bottom, 5)
            
            if recipes.isEmpty {
                Text("No recipes yet. Generate some from your ingredients!")
                    .foregroundColor(.secondary)
                    .padding()
                Spacer()
            } else {
                // 1. Replace List with ScrollView and LazyVStack
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(recipes) { recipe in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(recipe.title)
                                        .font(.headline)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .rotationEffect(.degrees(expandedRecipeID == recipe.id ? 180 : 0))
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    // 2. Use a single, smooth animation for the whole change
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        if expandedRecipeID == recipe.id {
                                            expandedRecipeID = nil
                                        } else {
                                            expandedRecipeID = recipe.id
                                        }
                                    }
                                }
                                
                                if expandedRecipeID == recipe.id {
                                    VStack(alignment: .leading, spacing: 8) {
                                        if let description = recipe.description, !description.isEmpty {
                                            Text(description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Divider()
                                        Text("Instructions")
                                            .fontWeight(.bold)
                                        ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, step in
                                            HStack(alignment: .top) {
                                                Text("\(index + 1).")
                                                Text(step)
                                            }
                                        }
                                    }
                                    // 3. Apply a transition for a fade-in/out effect
                                    .transition(.opacity)
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
    }
}
