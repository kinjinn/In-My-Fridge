import SwiftUI
import Auth0

struct ContentView: View {
    @StateObject var authManager = AuthenticationManager()
    
    // Data for the app
    @State private var ingredients: [Ingredient] = []
    @State private var recipes: [Recipe] = []
    
    // State for UI
    @State private var selectedTab: Tab = .fridge
    @State private var isLoading = false
    @State private var hasFetchedInitialData = false
    
    // State for sheets
    @State private var ingredientsToConfirm: [Ingredient] = []
    @State private var showingConfirmationSheet = false
    @State private var showingVoiceInput = false
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?

    enum Tab { case fridge, recipes }
    
    var body: some View {
        VStack(spacing: 0) {
            if authManager.isAuthenticated {
                loggedInContent
            } else {
                loggedOutContent
            }
        }
        .background(Color(.systemGray6).ignoresSafeArea())
        .sheet(isPresented: $showingCamera) {
            ImagePicker(image: $capturedImage)
        }
        .onChange(of: capturedImage) {
            if let image = capturedImage {
                uploadScannedImage(image: image)
                capturedImage = nil // Reset after processing
            }
        }
    }

    @ViewBuilder
    private var loggedInContent: some View {
        Group {
            if selectedTab == .fridge {
                IngredientsView(
                    ingredients: $ingredients,
                    isLoading: $isLoading,
                    onDelete: deleteIngredient,
                    onSaveQuantity: saveNewQuantity,
                    onAdd: addIngredient,
                    onGenerate: generateRecipes,
                    onAddByVoice: { showingVoiceInput = true },
                    onShowCamera: { showingCamera = true }
                )
            } else {
                RecipesView(recipes: $recipes)
            }
        }
        .onAppear {
            if !hasFetchedInitialData {
                fetchIngredients()
                hasFetchedInitialData = true
            }
        }
        .sheet(isPresented: $showingVoiceInput) {
            VoiceRecognitionView { text in
                showingVoiceInput = false
                addIngredientsFromVoice(text: text)
            }
        }
        .sheet(isPresented: $showingConfirmationSheet) {
            ConfirmationSheetView(
                ingredientsToConfirm: self.ingredientsToConfirm,
                onCancel: { showingConfirmationSheet = false },
                onConfirm: {
                    confirmAndAddIngredients()
                    showingConfirmationSheet = false
                }
            )
        }

        // Custom Tab Bar
        HStack(spacing: 0) {
            tabButton(title: "Fridge", isSelected: selectedTab == .fridge) { selectedTab = .fridge }
            tabButton(title: "Recipes", isSelected: selectedTab == .recipes) { selectedTab = .recipes }
        }
        .background(Color(.systemGray5)).cornerRadius(12).padding()
        
        Button("Log Out", action: authManager.logout).foregroundColor(.blue).padding(.bottom)
    }

    @ViewBuilder
    private var loggedOutContent: some View {
        VStack {
            Text("Recipe App 🍳").font(.largeTitle).padding()
            Button("Log In", action: authManager.login).buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .onAppear {
            // Reset state on logout
            hasFetchedInitialData = false
            ingredients = []
            recipes = []
        }
    }
    
    @ViewBuilder
    func tabButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity).padding()
                .background(isSelected ? Color.purple.opacity(0.2) : Color.clear)
                .foregroundColor(isSelected ? .purple : .primary)
                .cornerRadius(10)
        }
    }

    // MARK: - Helper Functions
    
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
                
                print("2. Scanned \(ingredientsToAdd.count) ingredients. Now saving to database...")
                
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
        guard let token = authManager.accessToken else { return }
        isLoading = true
        NetworkService.shared.fetchIngredients(accessToken: token) { fetched, _ in
            isLoading = false
            if let fetched = fetched { self.ingredients = fetched }
        }
    }
    
    func addIngredient(name: String, quantity: String) {
        guard !name.isEmpty, let token = authManager.accessToken else { return }
        NetworkService.shared.addIngredient(name: name, quantity: quantity.isEmpty ? "1" : quantity, accessToken: token) { new, _ in
            if let new = new { self.ingredients.append(new) }
        }
    }
    
    func deleteIngredient(at offsets: IndexSet) {
        guard let accessToken = authManager.accessToken else { return }
        
        // Get the ingredients to delete based on the row indexes
        let ingredientsToDelete = offsets.map { ingredients[$0] }
        
        // Loop through them and call the network service for each
        for ingredient in ingredientsToDelete {
            NetworkService.shared.deleteIngredient(id: ingredient.id, accessToken: accessToken) { success, error in
                if success {
                    print("✅ Successfully deleted \(ingredient.name) from database.")
                } else {
                    print("❌ Error deleting ingredient: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
        
        // Immediately remove the ingredients from the local array for a responsive UI
        ingredients.remove(atOffsets: offsets)
    }
    
    func saveNewQuantity(for ingredient: Ingredient, newQuantity: String) {
        guard let token = authManager.accessToken else { return }
        NetworkService.shared.updateIngredientQuantity(id: ingredient.id, newQuantity: newQuantity, accessToken: token) { updated, _ in
            if let updated = updated, let index = self.ingredients.firstIndex(where: { $0.id == updated.id }) {
                self.ingredients[index] = updated
            }
        }
    }
    
    func generateRecipes() {
        guard let token = authManager.accessToken else { return }
        let names = ingredients.filter { $0.isSelected }.map { $0.name }
        if names.isEmpty { return }
        
        isLoading = true
        NetworkService.shared.generateRecipes(ingredients: names, accessToken: token) { fetched, _ in
            isLoading = false
            if let fetched = fetched {
                self.recipes = fetched
                self.selectedTab = .recipes
            }
        }
    }

    func addIngredientsFromVoice(text: String) {
        guard let token = authManager.accessToken else { return }
        NetworkService.shared.parseTextForPreview(text: text, accessToken: token) { preview, _ in
            if let preview = preview, !preview.isEmpty {
                self.ingredientsToConfirm = preview
                self.showingConfirmationSheet = true
            }
        }
    }
    
    func confirmAndAddIngredients() {
        guard let accessToken = authManager.accessToken, !ingredientsToConfirm.isEmpty else { return }
        
        // Convert the confirmed Ingredient models to ScannedIngredient models for the API
        let scannedIngredients = ingredientsToConfirm.map {
            ScannedIngredient(name: $0.name, quantity: $0.quantity)
        }
        
        print("Confirming and adding \(scannedIngredients.count) ingredients from voice...")
        
        // ✅ FIX: Call the batchAddIngredients function with the voice results
        NetworkService.shared.batchAddIngredients(ingredients: scannedIngredients, accessToken: accessToken) { newIngredients, error in
            if let error = error {
                print("❌ Error batch-adding ingredients from voice: \(error.localizedDescription)")
            } else if newIngredients != nil {
                print("✅ Successfully saved voice ingredients. Refreshing list.")
                fetchIngredients()
            }
            // Clear the confirmation list regardless of success or failure
            self.ingredientsToConfirm = []
        }
    }
}
