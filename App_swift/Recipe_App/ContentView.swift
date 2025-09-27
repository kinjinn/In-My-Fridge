// ContentView.swift
import SwiftUI
import Auth0

struct ContentView: View {
    @StateObject var authManager = AuthenticationManager()
    @State private var ingredients: [Ingredient] = []
    @State private var recipes: [Recipe] = [] // State to hold recipes
    @State private var isLoading = false // For a loading indicator
    
    // State for the new ingredient form
    @State private var newIngredientName = ""
    @State private var newIngredientQuantity = ""

    var body: some View {
        VStack {
            if authManager.isAuthenticated, let accessToken = authManager.accessToken {
                // --- Logged In View ---
                Text("My Ingredients")
                    .font(.title)
                    .padding(.bottom)

                // --- FORM TO ADD NEW INGREDIENT ---
                HStack {
                    TextField("Ingredient Name", text: $newIngredientName)
                        .textFieldStyle(.roundedBorder) // Polish: Added style
                    TextField("Quantity", text: $newIngredientQuantity)
                        .textFieldStyle(.roundedBorder) // Polish: Added style
                    Button("Add", action: addIngredient)
                        .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)

                // --- LIST OF EXISTING INGREDIENTS ---
                List { // Bug Fix: Consolidated into one list
                    Section(header: Text("In Your Fridge")) { // Polish: Added header
                        if ingredients.isEmpty {
                            // Polish: Added "empty state" view
                            Text("No ingredients yet. Add one above to get started!")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(ingredients) { ingredient in
                                VStack(alignment: .leading) {
                                    Text(ingredient.name).font(.headline)
                                    Text("Quantity: \(ingredient.quantity)").font(.subheadline).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped) // A slightly cleaner list style
                .onAppear {
                    // Fetch ingredients when the view first appears
                    fetchIngredients()
                }
                
                // --- Generate Recipes Section ---
                if !ingredients.isEmpty {
                    Button(action: { generateRecipes(token: accessToken) }) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("✨ Generate Recipes!")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
                
                ScrollView {
                    ForEach(recipes) { recipe in
                        recipeCard(for: recipe)
                    }
                }
                
                Spacer()
                Button("Log Out", action: authManager.logout)
                    .padding(.bottom)

            } else {
                // --- Logged Out View ---
                Text("Recipe App 🍳")
                    .font(.largeTitle)
                    .padding()
                Button("Log In", action: authManager.login)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    // --- Helper Functions ---
    
    @ViewBuilder
    private func recipeCard(for recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(recipe.title).font(.headline)
            Text(recipe.description).font(.caption).foregroundColor(.secondary)
            Divider()
            Text("Instructions").fontWeight(.bold)
            ForEach(Array(recipe.instructions.enumerated()), id: \.offset){ index, step in
                Text("\(index + 1). \(step)")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.vertical, 5)
    }
    
    func fetchIngredients() {
        guard let accessToken = authManager.accessToken else { return }
        
        NetworkService.shared.fetchIngredients(accessToken: accessToken) { fetchedIngredients, error in
            if let error = error {
                print("❌ Error fetching ingredients: \(error.localizedDescription)")
                // Clear the list if there's an error (like user not found)
                self.ingredients = []
                return
            }
            if let fetchedIngredients = fetchedIngredients {
                print("✅ Successfully fetched \(fetchedIngredients.count) ingredients.")
                self.ingredients = fetchedIngredients
            }
        }
    }
    
    func addIngredient() {
        guard !newIngredientName.isEmpty, let accessToken = authManager.accessToken else { return }
        
        NetworkService.shared.addIngredient(name: newIngredientName, quantity: newIngredientQuantity, accessToken: accessToken) { newIngredient, error in
            if let error = error {
                print("❌ Error adding ingredient: \(error.localizedDescription)")
                return
            }
            
            if newIngredient != nil {
                print("✅ Successfully added ingredient.")
                // Clear the text fields
                newIngredientName = ""
                newIngredientQuantity = ""
                // Refresh the list to show the new ingredient
                fetchIngredients()
            }
        }
    }
    private func generateRecipes(token: String) {
            isLoading = true
            let ingredientNames = ingredients.map { $0.name } // Get just the names
            NetworkService.shared.generateRecipes(ingredients: ingredientNames, accessToken: token) { fetchedRecipes, error in
                isLoading = false
                if let error = error {
                    print("❌ Error generating recipes: \(error.localizedDescription)")
                    return
                }
                if let fetchedRecipes = fetchedRecipes {
                    print("✅ Successfully generated \(fetchedRecipes.count) recipes.")
                    self.recipes = fetchedRecipes
                }
            }
        }
}
