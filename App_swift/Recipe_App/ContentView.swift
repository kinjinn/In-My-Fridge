// ContentView.swift
import SwiftUI
import Auth0

struct ContentView: View {
    // --- STATE VARIABLES ---
    // Manages the user's login state for the whole app
    @StateObject var authManager = AuthenticationManager()
    
    // Manages the list of ingredients from the network
    @State private var ingredients: [Ingredient] = []
    
    // Controls whether the voice input sheet is shown
    @State private var showingVoiceInput = false
    
    // State for the new ingredient form fields
    @State private var newIngredientName = ""
    @State private var newIngredientQuantity = ""
    
    @State private var ingredientsToConfirm: [Ingredient] = []
    @State private var showingConfirmationSheet = false

    // --- BODY ---
    var body: some View {
        NavigationStack {
            VStack {
                // Check if the user is authenticated and show the appropriate view
                if authManager.isAuthenticated {
                    mainAppView
                } else {
                    loginView
                }
            }
            .navigationTitle("In My Fridge 🍳")
        }
    }

    // --- SUBVIEWS ---
    
    // A computed property for the main Logged In UI
    @ViewBuilder
    private var mainAppView: some View {
        VStack {
            // --- FORM TO ADD NEW INGREDIENT ---
            HStack {
                TextField("Ingredient Name", text: $newIngredientName)
                    .textFieldStyle(.roundedBorder)
                TextField("Quantity", text: $newIngredientQuantity)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                Button("Add", action: addIngredient)
                    .buttonStyle(.borderedProminent)
            }
            .padding([.horizontal, .top])

            // --- LIST OF EXISTING INGREDIENTS ---
            List {
                ForEach(ingredients) { ingredient in
                    VStack(alignment: .leading) {
                        Text(ingredient.name).font(.headline)
                        Text("Quantity: \(ingredient.quantity)").font(.subheadline)
                    }
                }
                .onDelete(perform: deleteIngredient) // Optional: Adds swipe-to-delete
            }
            .listStyle(.plain)
            
            // --- ACTION BUTTONS ---
            HStack {
                Button("Add by Voice 🎤") {
                    showingVoiceInput = true
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Log Out") {
                    authManager.logout()
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding()
        }
        // This modifier presents the VoiceRecognitionView as a pop-up sheet
        .sheet(isPresented: $showingVoiceInput) {
            VoiceRecognitionView { transcribedText in
                showingVoiceInput = false // Dismiss the sheet
                addIngredientsFromVoice(text: transcribedText)
            }
        }
        .sheet(isPresented: $showingConfirmationSheet) {
            // This is the new confirmation view
            VStack {
                Text("Confirm Ingredients")
                    .font(.largeTitle)
                    .padding()
                
                List(ingredientsToConfirm) { ingredient in
                    VStack(alignment: .leading) {
                        Text(ingredient.name).font(.headline)
                        Text("Quantity: \(ingredient.quantity)").font(.subheadline)
                    }
                }
                
                HStack(spacing: 20) {
                    Button("Cancel") {
                        showingConfirmationSheet = false
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Confirm & Add") {
                        confirmAndAddIngredients()
                        showingConfirmationSheet = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
    }

    // A computed property for the Logged Out UI
    @ViewBuilder
    private var loginView: some View {
        VStack {
            Spacer()
            Text("Log in to manage your pantry.")
                .font(.title2)
                .multilineTextAlignment(.center)
            Spacer()
            
            Button("Log In / Sign Up") {
                authManager.login()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }
    
    // --- HELPER FUNCTIONS ---
    
    func fetchIngredients() {
        guard let accessToken = authManager.accessToken else { return }
        
        NetworkService.shared.fetchIngredients(accessToken: accessToken) { fetchedIngredients, error in
            if let error = error {
                print("❌ Error fetching ingredients: \(error.localizedDescription)")
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
    
    // Optional: You will need to implement deleteIngredient in your NetworkService
    // and a DELETE endpoint on your backend for this to work.
    func deleteIngredient(at offsets: IndexSet) {
        // guard let accessToken = authManager.accessToken else { return }
        // let ingredientsToDelete = offsets.map { ingredients[$0] }
        // ... call your network service to delete ...
        // On completion, call fetchIngredients() or remove from local array
        ingredients.remove(atOffsets: offsets)
    }
    func addIngredientsFromVoice(text: String) {
        guard let accessToken = authManager.accessToken else { return }
            
            NetworkService.shared.parseTextForPreview(text: text, accessToken: accessToken) { previewIngredients, error in
                // Check if we got ingredients back AND that the array is not empty
                if let previewIngredients = previewIngredients, !previewIngredients.isEmpty {
                    // SUCCESS: This should be running now.
                    print("✅ Swift App received \(previewIngredients.count) ingredients to confirm.")
                    self.ingredientsToConfirm = previewIngredients
                    self.showingConfirmationSheet = true
                } else {
                    // FAILURE: This is what's likely running now.
                    print("❌ Swift App failed to get preview ingredients. Error: \(String(describing: error))")
                }
            }
    }

    // This function will be called from the new confirmation sheet
    func addIngredient(name: String, quantity: String) {
        guard !name.isEmpty, let accessToken = authManager.accessToken else { return }
        
        // Calls the network service using the parameters passed into the function
        NetworkService.shared.addIngredient(name: name, quantity: quantity, accessToken: accessToken) { newIngredient, error in
            if newIngredient != nil {
                print("✅ Successfully added confirmed ingredient: \(name).")
                // We don't clear text fields here, just refresh the list.
                fetchIngredients()
            } else if let error = error {
                print("❌ Error adding confirmed ingredient: \(error.localizedDescription)")
            }
        }
    }
    func confirmAndAddIngredients() {
        // Loop through the ingredients the user confirmed
        for ingredient in ingredientsToConfirm {
            // Call the version of addIngredient that takes parameters
            addIngredient(name: ingredient.name, quantity: ingredient.quantity)
        }
        // Clear the temporary list
        ingredientsToConfirm = []
    }
}

#Preview {
    ContentView()
}
