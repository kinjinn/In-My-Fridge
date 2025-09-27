// ContentView.swift
import SwiftUI
import Auth0

struct ContentView: View {
    @StateObject var authManager = AuthenticationManager()
    @State private var ingredients: [Ingredient] = []
    
    // State for the new ingredient form
    @State private var newIngredientName = ""
    @State private var newIngredientQuantity = ""

    var body: some View {
        VStack {
            if authManager.isAuthenticated {
                // --- Logged In View ---
                Text("My Ingredients")
                    .font(.title)
                    .padding(.bottom)

                // --- FORM TO ADD NEW INGREDIENT ---
                HStack {
                    TextField("Ingredient Name", text: $newIngredientName)
                    TextField("Quantity", text: $newIngredientQuantity)
                    Button("Add", action: addIngredient)
                        .buttonStyle(.borderedProminent)
                }
                .padding()

                // --- LIST OF EXISTING INGREDIENTS ---
                List(ingredients) { ingredient in
                    VStack(alignment: .leading) {
                        Text(ingredient.name).font(.headline)
                        Text("Quantity: \(ingredient.quantity)").font(.subheadline)
                    }
                }
                .onAppear {
                    // Fetch ingredients when the view first appears
                    fetchIngredients()
                }
                
                Spacer()
                Button("Log Out", action: authManager.logout)

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
}
