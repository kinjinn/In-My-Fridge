// IngredientsView.swift
import SwiftUI

struct IngredientsView: View {
    @Binding var ingredients: [Ingredient]
    @Binding var newIngredientName: String
    @Binding var newIngredientQuantity: String
    @Binding var isLoading: Bool
    
    // ✅ FIX: Add the new closure
    var onShowCamera: () -> Void
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
                
                // ✅ FIX: Add the camera button
                Button(action: onShowCamera) {
                    Image(systemName: "camera.fill")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            List {
                Section(header: Text("In Your Fridge")) {
                    if ingredients.isEmpty {
                        Text("No ingredients yet. Add one above to get started!")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach($ingredients) { $ingredient in
                            Toggle(isOn: $ingredient.isSelected) {
                                VStack(alignment: .leading) {
                                    Text(ingredient.name)
                                        .font(.headline)
                                    Text("Qty: \(ingredient.quantity)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .toggleStyle(CheckboxToggleStyle())
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

// Your CheckboxToggleStyle is perfect and needs no changes.
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? .purple : .gray)
                    .imageScale(.large)
                configuration.label
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
