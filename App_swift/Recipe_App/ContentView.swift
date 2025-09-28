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
    
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    
    enum Tab {
        case fridge, recipes
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if authManager.isAuthenticated, let accessToken = authManager.accessToken {
                // Main content area
                Group {
                    switch selectedTab {
                    case .fridge:
                        IngredientsView(
                            ingredients: $ingredients,
                            newIngredientName: $newIngredientName,
                            newIngredientQuantity: $newIngredientQuantity,
                            isLoading: $isLoading,
                            onShowCamera: { showingCamera = true },
                            onAddIngredient: addIngredient,
                            onGenerateRecipes: { generateRecipes(token: accessToken) }
                        )
                    case .recipes:
                        RecipesView(recipes: $recipes)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                
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
        .background(Color(UIColor.systemGray6).ignoresSafeArea())
        .sheet(isPresented: $showingCamera) {
            ImagePicker(image: $capturedImage)
        }
        .onChange(of: capturedImage) {
            if let image = capturedImage{
                uploadScannedImage(image: image)
                capturedImage = nil
            }
        }
        .onAppear {
             if authManager.isAuthenticated {
                 fetchIngredients()
             }
         }
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
    
    // MARK: - Network and helper functions
    
    // ✅ THIS FUNCTION IS NOW COMPLETE
    func uploadScannedImage(image: UIImage) {
        guard let accessToken = authManager.accessToken else { return }
        
        isLoading = true
        print("1. Starting image scan...")
        
        // Step 1: Scan the image to get the list of ingredients from the AI
        NetworkService.shared.scanIngredients(from: image, accessToken: accessToken) { scannedIngredients, error in
            guard let ingredientsToAdd = scannedIngredients, error == nil else {
                print("❌ Error scanning image: \(error?.localizedDescription ?? "Unknown error")")
                isLoading = false
                return
            }
            
            print("2. Scanned \(ingredientsToAdd.count) ingredients from image. Now saving to database...")
            
            // Step 2: Send that list to the server to be saved in the database
            NetworkService.shared.batchAddIngredients(ingredients: ingredientsToAdd, accessToken: accessToken) { newIngredients, error in
                isLoading = false // End loading indicator
                if let error = error {
                    print("❌ Error batch-adding ingredients: \(error.localizedDescription)")
                    return
                }
                
                if newIngredients != nil {
                    print("3. Successfully saved scanned ingredients. Refreshing list.")
                    // Step 3: Refresh the UI to show the new ingredients
                    fetchIngredients()
                }
            }
        }
    }
    
    func fetchIngredients() {
        guard let accessToken = authManager.accessToken else { return }
        
        NetworkService.shared.fetchIngredients(accessToken: accessToken) { fetchedIngredients, error in
            if let fetchedIngredients = fetchedIngredients {
                self.ingredients = fetchedIngredients
            }
        }
    }
    
    func addIngredient() {
        guard !newIngredientName.isEmpty, let accessToken = authManager.accessToken else { return }
        
        NetworkService.shared.addIngredient(name: newIngredientName, quantity: newIngredientQuantity, accessToken: accessToken) { newIngredient, error in
            if newIngredient != nil {
                newIngredientName = ""
                newIngredientQuantity = ""
                fetchIngredients()
            }
        }
    }
    
    private func generateRecipes(token: String) {
        isLoading = true
        let ingredientNames = ingredients.filter { $0.isSelected }.map { $0.name }
        NetworkService.shared.generateRecipes(ingredients: ingredientNames, accessToken: token) { fetchedRecipes, error in
            isLoading = false
            if let fetchedRecipes = fetchedRecipes {
                self.recipes = fetchedRecipes
            }
        }
    }
}
