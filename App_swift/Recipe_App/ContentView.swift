import SwiftUI
import Auth0

struct ContentView: View {
    @StateObject var authManager = AuthenticationManager()
    
    @State private var ingredients: [Ingredient] = []
    @State private var recipes: [Recipe] = []
    @State private var isLoading = false
    
    @State private var newIngredientName = ""
    @State private var newIngredientQuantity = ""
    
    @State private var selectedTab: Tab = .fridge
    
    enum Tab {
        case fridge, recipes
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if authManager.isAuthenticated, let accessToken = authManager.accessToken {
                // Show content based on selected tab
                switch selectedTab {
                case .fridge:
                    IngredientsView(
                        ingredients: $ingredients,
                        newIngredientName: $newIngredientName,
                        newIngredientQuantity: $newIngredientQuantity,
                        isLoading: $isLoading,
                        onAddIngredient: addIngredient,
                        onGenerateRecipes: { generateRecipes(token: accessToken) }
                    )
                    .onAppear {
                        fetchIngredients()
                    }
                    
                case .recipes:
                    RecipesView(recipes: $recipes)
                }
                
                // Custom Tab Bar
                HStack(spacing: 0) {
                    tabButton(title: "Fridge", isSelected: selectedTab == .fridge) {
                        selectedTab = .fridge
                    }
                    tabButton(title: "Recipes", isSelected: selectedTab == .recipes) {
                        selectedTab = .recipes
                    }
                }
                .background(Color(UIColor.systemGray5))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Log Out button at bottom
                Button("Log Out", action: authManager.logout)
                    .padding(.bottom)
                    .foregroundColor(.blue)
                
            } else {
                // Logged out view
                VStack {
                    Text("Recipe App 🍳")
                        .font(.largeTitle)
                        .padding()
                    Button("Log In", action: authManager.login)
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6).ignoresSafeArea())
    }
    
    @ViewBuilder
    func tabButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSelected ? Color.purple.opacity(0.2) : Color.clear)
                .foregroundColor(isSelected ? .purple : .primary)
                .cornerRadius(10)
        }
    }
    
    // MARK: - Network and helper functions (unchanged)
    
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
        let selectedIngredients = ingredients.filter { $0.isSelected }
        let ingredientNames = selectedIngredients.map { $0.name }
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
