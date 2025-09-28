// IngredientsView.swift
import SwiftUI

struct IngredientsView: View {
    // Data and state passed down from the parent ContentView
    @Binding var ingredients: [Ingredient]
    @Binding var isLoading: Bool
    
    // Closures to communicate actions back to the ContentView
    var onDelete: (IndexSet) -> Void
    var onSaveQuantity: (Ingredient, String) -> Void
    var onAdd: (String, String) -> Void
    var onGenerate: () -> Void
    var onAddByVoice: () -> Void
    var onShowCamera: () -> Void // For the new camera feature
    
    // State local to this view
    @State private var newIngredientName = ""
    @State private var newIngredientQuantity = ""
    @State private var editingIngredientID: String? = nil
    @State private var editingQuantityText: String = ""

    var body: some View {
        VStack {
            Text("Ingredients").font(.largeTitle).padding()
            
            // --- Form for adding new ingredients ---
            HStack {
                TextField("Ingredient Name", text: $newIngredientName)
                    .textFieldStyle(.roundedBorder)
                TextField("Quantity", text: $newIngredientQuantity)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    // Call the onAdd closure from ContentView
                    onAdd(newIngredientName, newIngredientQuantity)
                    // Clear the fields after adding
                    newIngredientName = ""
                    newIngredientQuantity = ""
                }
                .buttonStyle(.borderedProminent)
            }.padding(.horizontal)
            
            // --- List of current ingredients ---
            List {
                Section(header: Text("In Your Fridge")) {
                    if ingredients.isEmpty {
                        Text("No ingredients yet. Add one to get started!").foregroundColor(.secondary)
                    } else {
                        ForEach($ingredients) { $ingredient in
                            HStack {
                                // Checkbox for selecting ingredients for recipes
                                Toggle(isOn: $ingredient.isSelected) {
                                    Text(ingredient.name).font(.headline)
                                }.toggleStyle(CheckboxToggleStyle())
                                
                                Spacer()
                                
                                // Tappable quantity text field for editing
                                if editingIngredientID == ingredient.id {
                                    TextField("Quantity", text: $editingQuantityText)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 120)
                                        .multilineTextAlignment(.trailing)
                                        .onSubmit {
                                            // When submitted, save the new quantity
                                            onSaveQuantity(ingredient, editingQuantityText)
                                            editingIngredientID = nil
                                        }
                                } else {
                                    Text("Qty: \(ingredient.quantity)")
                                        .onTapGesture {
                                            editingIngredientID = ingredient.id
                                            editingQuantityText = ingredient.quantity
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: onDelete) // Enable swipe-to-delete
                    }
                }
            }
            .listStyle(.insetGrouped)
            
            // --- Action buttons at the bottom ---
            HStack(spacing: 20) {
                // Voice Input Button
                Button(action: onAddByVoice) {
                    Image(systemName: "mic.fill").font(.title2)
                }.buttonStyle(.bordered)
                
                // Camera Scan Button
                Button(action: onShowCamera) {
                    Image(systemName: "camera.fill").font(.title2)
                }.buttonStyle(.bordered)

                if !ingredients.filter({ $0.isSelected }).isEmpty {
                    // Generate Recipes Button (only appears if ingredients are selected)
                    Button(action: onGenerate) {
                        if isLoading {
                            ProgressView()
                                .padding(.horizontal)
                        } else {
                            Text("✨ Generate Recipes!")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding([.horizontal, .bottom])
        }
    }
}

// Custom style for the checkbox toggle
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? .purple : .gray)
                configuration.label
            }
        }.buttonStyle(PlainButtonStyle())
    }
}
