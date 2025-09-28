import SwiftUI

struct IngredientsView: View {
    @Binding var ingredients: [Ingredient]
    @Binding var newIngredientName: String
    @Binding var newIngredientQuantity: String
    @Binding var isLoading: Bool
    
    var onAddIngredient: () -> Void
    var onGenerateRecipes: () -> Void
    
    var body: some View {
        VStack {
            Text("Ingredients")
                .font(.title)
                .padding(.bottom)
            
            HStack {
                TextField("Ingredient Name", text: $newIngredientName)
                    .textFieldStyle(.roundedBorder)
                TextField("Quantity", text: $newIngredientQuantity)
                    .textFieldStyle(.roundedBorder)
                Button("Add", action: onAddIngredient)
                    .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
            
            List {
                Section(header: Text("In Your Fridge")) {
                    if ingredients.isEmpty {
                        Text("No ingredients yet. Add one above to get started!")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(ingredients) { ingredient in
                            HStack {
                                Text(ingredient.name)
                                Spacer()
                                Text("Qty: \(ingredient.quantity)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            
            if !ingredients.isEmpty {
                Button(action: onGenerateRecipes) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("✨ Generate Recipes!")
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
    }
}
